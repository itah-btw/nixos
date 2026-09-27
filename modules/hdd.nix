# The TV's data disk (500 GB ST3500312CS) + weekly SMART check. Empty since
# 2026-09-28: the Kodi addons that were its only contents went with Kodi.
_: {
  flake.nixosModules.hdd =
    { pkgs, ... }:
    {
      # By label, not UUID: mkfs assigns a new UUID on every format. Relabelled
      # to hdd on the disk with e2label, which has to happen before a deploy --
      # `nofail` makes a wrong label a silent no-mount, not a boot failure.
      fileSystems."/mnt/media" = {
        device = "/dev/disk/by-label/hdd";
        fsType = "ext4";
        options = [
          "noatime"
          "nofail"
        ];
      };

      # The only SMART check on this disk. Journals, not a daemon: Bigscreen
      # runs no notification daemon. Root, because smartctl needs raw device
      # access. NixOS dropped services.smartd.
      systemd.services.hdd-disk-health =
        let
          script = pkgs.writeShellApplication {
            name = "hdd-disk-health";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.gawk
              pkgs.smartmontools
              # logger(1); systemd gives services no /usr/bin.
              pkgs.util-linux
            ];
            text = ''
              # The whole disk: SMART attributes live on the device and
              # smartctl misreports on a partition.
              device=/dev/sda
              log() { logger -t hdd-disk-health -- "$1"; }

              # nofail, and this box is switched off at the wall.
              if [ ! -b "$device" ]; then
                log "$device is absent; nothing to check"
                exit 0
              fi

              # errexit is on, so the status must be caught on the || branch.
              # smartctl's status is a bitmask: bit 1 (value 2) means it could not
              # parse its own arguments, which must never read as a healthy disk.
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

              # Two failure signals, because neither is enough alone: the -H
              # verdict (authoritative, but only trips once the vendor calls it
              # done) and any *pre-fail* attribute whose VALUE reached 0, which
              # catches a disk degrading early. Pre-fail only: healthy drives
              # report VALUE 0 for attributes they do not implement. Compared
              # numerically, since smartctl pads VALUE to three columns. Raw
              # counts are vendor-specific and never compared.
              zeroed=$(printf '%s\n' "$out" |
                awk '$1 ~ /^[0-9]+$/ && NF >= 10 && $7 == "Pre-fail" && $4 + 0 == 0 { printf "%s ", $2 }')

              # Raw counts, informational: reallocated (5), pending (197).
              # RAW_VALUE is column 10, but vendors append more columns and
              # Temperature_Celsius ends in a history whose last token reads
              # "0)", so take the first all-digit field from column 10 on.
              raw() {
                printf '%s\n' "$out" |
                  awk -v id="$1" '$1 == id { for (i = 10; i <= NF; i++) if ($i ~ /^[0-9]+$/) { print $i; exit } }'
              }
              temperature=$(raw 194)
              [ -n "$temperature" ] || temperature=$(raw 190)

              # The doubled dollar-braces below are Nix's escape for a literal
              # dollar-brace and are NOT optional: in an indented string a plain
              # one interpolates at build time and ships as "health=health:-unknown".
              summary="$device health=''${health:-unknown} reallocated=$(raw 5) pending=$(raw 197) temperature=$temperature"

              # An unreadable or unrecognised verdict counts as failure: a
              # check that cannot tell must not look like a healthy disk.
              if [ "$health" != "PASSED" ] || [ -n "$zeroed" ]; then
                log "FAIL: $summary; attributes at zero: ''${zeroed:-none}"
                # Full attribute table and self-test log, once, when it matters.
                printf '%s\n' "$out" | logger -t hdd-disk-health
              else
                log "OK: $summary"
              fi
            '';
          };
        in
        {
          description = "Weekly SMART check on the data HDD, reported to the journal";
          # No wantedBy: the timer activates its own unit.
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${script}/bin/hdd-disk-health";
            # A few seconds of reads on a 5400rpm disk; never compete with Stremio.
            CPUSchedulingPolicy = "idle";
            IOSchedulingClass = "idle";
          };
        };

      systemd.timers.hdd-disk-health = {
        description = "Weekly SMART check on the data HDD";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          # Small hours on Sunday; the TV is often off then.
          OnCalendar = "Sun *-*-* 06:20:00";
          # The TV is often off at that hour, so catch up at the next boot
          # rather than losing a whole week.
          Persistent = true;
          RandomizedDelaySec = "20m";
        };
      };
    };
}
