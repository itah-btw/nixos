# TV media HDD (500 GB ST3500312CS) + weekly SMART health check.
# Ported verbatim from the box's configuration.nix.
{ ... }:
{
  flake.nixosModules.tv-media =
    { pkgs, ... }:
    {
      # Secondary 500 GB HDD (ST3500312CS, 5400rpm rotational). It was
      # attached after installation, so nixos-generate-config never saw it
      # and it is absent from hardware-configuration-tv.nix.
      #
      # Reformatted from NTFS to ext4. Nix requires POSIX semantics --
      # hardlinks, xattrs, real ownership and file locking -- which NTFS
      # cannot provide, so an NTFS /nix/store is not merely slow, it is
      # unsupported and breaks the store.
      #
      # Mounted by label, not UUID: mkfs assigns a fresh UUID on every
      # format, so a by-uuid mount silently rots the next time the drive is
      # reformatted.
      #
      # noatime keeps the drive quiet during playback. nofail keeps the
      # system bootable if the drive is ever unplugged or fails.
      #
      # No uid=/gid= options: those are NTFS-specific and ext4 rejects them
      # ("ext4: Unknown parameter 'uid'"). ext4 stores real ownership, so
      # the drive root is owned by itah via
      # `mkfs.ext4 -E root_owner=1000:100` instead.
      fileSystems."/mnt/media" = {
        device = "/dev/disk/by-label/tv-media";
        fsType = "ext4";
        options = [
          "noatime"
          "nofail"
        ];
      };

      # The 500 GB media HDD holds the only copy of the media library, and
      # nothing on this box has ever read its SMART data -- NixOS removed
      # services.smartd, so there is no daemon and no timer. A rotational
      # disk normally reports failing attributes for weeks before it drops
      # off, which is exactly the window worth catching. It logs to the
      # journal rather than notifying, because Plasma Bigscreen runs no
      # notification daemon and the journal is the only sink here.
      #
      # Runs as root: smartctl needs raw device access and /dev/sda is
      # group disk.
      systemd.services.tv-media-disk-health =
        let
          script = pkgs.writeShellApplication {
            name = "tv-media-disk-health";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.gawk
              pkgs.smartmontools
              # logger(1); systemd gives services no /usr/bin.
              pkgs.util-linux
            ];
            text = ''
              device=/dev/sda
              log() { logger -t tv-media-disk-health -- "$1"; }

              # The mount is nofail and this box gets switched off at the wall, so
              # the disk really can be missing at boot.
              if [ ! -b "$device" ]; then
                log "$device is absent; nothing to check"
                exit 0
              fi

              # errexit is on (writeShellApplication), so the status has to be caught
              # on the || branch or a smartctl failure kills the script before it can
              # report anything. smartctl's status is a bitmask: bit 1 (value 2) means
              # it could not parse its own arguments, which must never be reported as
              # a healthy disk.
              rc=0
              out=$(smartctl -H -A -l error "$device" 2>&1) || rc=$?
              if [ "$rc" -ne 0 ]; then
                if [ $((rc & 2)) -ne 0 ]; then
                  log "FATAL: smartctl rejected its arguments (status $rc); the check did not run"
                else
                  log "FAIL: could not read SMART from $device (status $rc): $(printf '%s' "$out" | tr '\n' ' ')"
                fi
                exit 0
              fi

              health=$(printf '%s\n' "$out" |
                awk -F': ' '/^SMART overall-health self-assessment test result:/ { print $2; exit }')

              # Two independent failure signals, because on their own neither is
              # enough.
              #
              # 1. The drive's own verdict from -H. Authoritative and vendor-neutral,
              #    but only trips once the vendor decides the disk is done.
              # 2. Any *pre-fail* attribute whose normalized VALUE has reached 0,
              #    which catches a disk degrading well before it says so itself.
              #
              # Pre-fail only, on purpose. Plenty of otherwise-healthy drives report
              # VALUE 0 for vendor-specific attributes they do not implement, so
              # flagging every zero would make this fire every week on a good disk.
              #
              # The comparison is numeric because smartctl pads VALUE to three
              # columns: a tripped attribute reads "000", not "0". Raw sector counts
              # are not compared at all -- they are vendor-specific and not
              # comparable across models.
              zeroed=$(printf '%s\n' "$out" |
                awk '$1 ~ /^[0-9]+$/ && NF >= 10 && $7 == "Pre-fail" && $4 + 0 == 0 { printf "%s ", $2 }')

              # Raw counts, informational only. Reallocated (id 5) is sectors the disk
              # has already written around; pending (197) is sectors it has given up
              # reading but not yet replaced.
              #
              # RAW_VALUE is column 10, but the vendor is free to append more columns
              # after it -- Temperature_Celsius ends in a parenthesised history, whose
              # last token reads as "0)" and would otherwise be reported as the
              # temperature. So take the first purely numeric field from column 10 on
              # rather than the last field on the line.
              raw() {
                printf '%s\n' "$out" |
                  awk -v id="$1" '$1 == id { for (i = 10; i <= NF; i++) if ($i ~ /^[0-9]+$/) { print $i; exit } }'
              }
              temperature=$(raw 194)
              [ -n "$temperature" ] || temperature=$(raw 190)

              # The doubled dollar-brace on the next two lines is Nix's escape for a
              # literal dollar-brace, and it is not optional. This text lives in a
              # Nix indented string, where a plain dollar-brace means antiquotation:
              # Nix interpolates it at build time and bakes a literal into the script
              # instead of letting the shell expand it. Written the obvious way, the
              # summary line ships as the fixed text "health=health:-unknown".
              summary="$device health=''${health:-unknown} reallocated=$(raw 5) pending=$(raw 197) temperature=$temperature"

              # Fail on either signal. An unreadable or unrecognised verdict counts
              # as a failure rather than passing quietly -- a check that cannot tell
              # must not look like a healthy disk.
              if [ "$health" != "PASSED" ] || [ -n "$zeroed" ]; then
                log "FAIL: $summary; attributes at zero: ''${zeroed:-none}"
                # Full attribute table and self-test log, once, when it matters.
                printf '%s\n' "$out" | logger -t tv-media-disk-health
              else
                log "OK: $summary"
              fi
            '';
          };
        in
        {
          description = "Weekly SMART check on the media HDD, reported to the journal";
          # Deliberately no wantedBy here. The timer below is the only thing that
          # should start this, and a timer activates its unit on its own, so pulling
          # the service into timers.target as well would run the check at every boot
          # and after every switch-to-configuration on top of the Sunday schedule.
          # Persistent on the timer still covers a week the TV spent switched off.
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${script}/bin/tv-media-disk-health";
            # A few seconds of reads on a 5400rpm disk; never compete with playback.
            CPUSchedulingPolicy = "idle";
            IOSchedulingClass = "idle";
          };
        };

      systemd.timers.tv-media-disk-health = {
        description = "Weekly SMART check on the media HDD";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          # Small hours on Sunday.
          OnCalendar = "Sun *-*-* 06:20:00";
          # The TV is often off at that hour, so catch up at the next boot
          # rather than losing a whole week.
          Persistent = true;
          RandomizedDelaySec = "20m";
        };
      };
    };
}
