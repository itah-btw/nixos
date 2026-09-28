# The TV's data disk (500 GB ST3500312CS) + weekly SMART check.
_: {
  flake.nixosModules.tv-hdd =
    { pkgs, ... }:
    {
      # By label, not UUID: mkfs reassigns the UUID on every format. e2label to
      # hdd on the disk before deploying -- nofail makes a wrong label a no-mount.
      fileSystems."/mnt/media" = {
        device = "/dev/disk/by-label/hdd";
        fsType = "ext4";
        options = [
          "noatime"
          "nofail"
        ];
      };

      # Journals, not a daemon: Bigscreen runs no notification daemon. Root, for
      # raw device access. NixOS dropped services.smartd.
      systemd.services.hdd-disk-health =
        let
          script = pkgs.writeShellApplication {
            name = "hdd-disk-health";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.gawk
              pkgs.smartmontools
              # logger(1); systemd services get no /usr/bin.
              pkgs.util-linux
            ];
            text = ''
              # Whole disk, not a partition: attributes live on the device.
              device=/dev/sda
              log() { logger -t hdd-disk-health -- "$1"; }

              # nofail: this box is switched off at the wall.
              if [ ! -b "$device" ]; then
                log "$device is absent; nothing to check"
                exit 0
              fi

              # errexit is on, so catch the status on the || branch. smartctl's status
              # is a bitmask: 2 means it could not parse its own arguments.
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

              # Two signals, because neither suffices alone: the -H verdict (only
              # trips once the vendor calls it done) and a *pre-fail* attribute at
              # VALUE 0, which catches a disk degrading early. Pre-fail only --
              # healthy drives report 0 for attributes they do not implement.
              zeroed=$(printf '%s\n' "$out" |
                awk '$1 ~ /^[0-9]+$/ && NF >= 10 && $7 == "Pre-fail" && $4 + 0 == 0 { printf "%s ", $2 }')

              # Raw counts, informational: reallocated (5), pending (197). Take the
              # first all-digit field from column 10; vendors append columns, and
              # Temperature_Celsius ends in a history whose last token reads "0)".
              raw() {
                printf '%s\n' "$out" |
                  awk -v id="$1" '$1 == id { for (i = 10; i <= NF; i++) if ($i ~ /^[0-9]+$/) { print $i; exit } }'
              }
              temperature=$(raw 194)
              [ -n "$temperature" ] || temperature=$(raw 190)

              # The doubled dollar-braces are Nix's escape and NOT optional: a plain
              # one interpolates at build time and ships as "health=health:-unknown".
              summary="$device health=''${health:-unknown} reallocated=$(raw 5) pending=$(raw 197) temperature=$temperature"

              # A verdict we cannot read counts as failure, not health.
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
            # Never compete with Stremio for a 5400rpm disk.
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
          # The TV is often off at that hour; catch up rather than lose a week.
          Persistent = true;
          RandomizedDelaySec = "20m";
        };
      };
    };
}
