# TV media HDD (500 GB ST3500312CS) + weekly SMART health check.
# Parsing details for the script below are in the tv skill, trap 5.
_: {
  flake.nixosModules.tv-media =
    { pkgs, ... }:
    {
      # Attached after installation, so it is absent from
      # hardware-configuration-tv.nix. By label, not UUID: mkfs assigns a new
      # UUID on every format. ext4, not NTFS: Nix needs hardlinks, xattrs and
      # real ownership. noatime keeps it quiet during playback, nofail keeps
      # the box bootable without it. Drive root owned via
      # `mkfs.ext4 -E root_owner=1000:100`; no uid=/gid= options (ext4
      # rejects them).
      fileSystems."/mnt/media" = {
        device = "/dev/disk/by-label/tv-media";
        fsType = "ext4";
        options = [
          "noatime"
          "nofail"
        ];
      };

      # The only copy of the media library, and nothing here has ever read its
      # SMART data: NixOS dropped services.smartd, so this timer is the only
      # check. Logs to the journal because Plasma Bigscreen runs no
      # notification daemon. Root, because smartctl needs raw device access.
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
              # enough: the drive's own -H verdict (authoritative, but only
              # trips once the vendor calls it done) and any *pre-fail*
              # attribute whose VALUE has reached 0 (catches a disk degrading
              # well before it says so). Pre-fail only, because healthy drives
              # report VALUE 0 for vendor attributes they do not implement.
              # Compared numerically: smartctl pads VALUE to three columns, so
              # a tripped attribute reads "000". Raw counts are never compared
              # -- they are vendor-specific.
              zeroed=$(printf '%s\n' "$out" |
                awk '$1 ~ /^[0-9]+$/ && NF >= 10 && $7 == "Pre-fail" && $4 + 0 == 0 { printf "%s ", $2 }')

              # Raw counts, informational only: reallocated (5) is sectors
              # already written around, pending (197) is sectors given up
              # reading. RAW_VALUE is column 10, but vendors append more
              # columns after it and Temperature_Celsius ends in a
              # parenthesised history whose last token reads as "0)", so take
              # the first all-digit field from column 10 on.
              raw() {
                printf '%s\n' "$out" |
                  awk -v id="$1" '$1 == id { for (i = 10; i <= NF; i++) if ($i ~ /^[0-9]+$/) { print $i; exit } }'
              }
              temperature=$(raw 194)
              [ -n "$temperature" ] || temperature=$(raw 190)

              # The doubled dollar-braces below are Nix's escape for a literal
              # dollar-brace and are not optional: this is an indented string,
              # so a plain one would be interpolated at build time and ship as
              # the fixed text "health=health:-unknown". See the tv skill,
              # trap 1.
              summary="$device health=''${health:-unknown} reallocated=$(raw 5) pending=$(raw 197) temperature=$temperature"

              # An unreadable or unrecognised verdict counts as failure: a
              # check that cannot tell must not look like a healthy disk.
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
          # No wantedBy here: the timer below is the only thing that should
          # start this, and a timer activates its own unit (tv skill, trap 7).
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
