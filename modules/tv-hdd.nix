_: {
  flake.nixosModules.tv-hdd =
    { constants, pkgs, ... }:
    {
      fileSystems.${constants.mediaMount} = {
        device = "/dev/disk/by-label/${constants.mediaLabel}";
        fsType = "ext4";
        options = [
          "noatime"
          "nofail"
          # Without this a slow spin-up still costs systemd's 90s default.
          "x-systemd.device-timeout=10s"
        ];
      };

      systemd.services.hdd-disk-health =
        let
          script = pkgs.writeShellApplication {
            name = "hdd-disk-health";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.gawk
              pkgs.gnused
              pkgs.smartmontools
              pkgs.util-linux
            ];
            text = ''
              # Derived from the media mount, never a hardcoded sda.
              log() { logger -t hdd-disk-health -- "$1"; }
              device=""
              src=$(findmnt -no SOURCE ${constants.mediaMount} 2>/dev/null || true)
              if [ -n "$src" ]; then
                canon=$(readlink -f "$src" 2>/dev/null || printf '%s' "$src")
                parent=$(lsblk -no PKNAME "$canon" 2>/dev/null | head -n 1 || true)
                if [ -n "$parent" ]; then
                  device="/dev/$parent"
                else
                  case "$canon" in
                    /dev/sd[a-z]|/dev/hd[a-z]|/dev/vd[a-z]) device="$canon" ;;
                    /dev/sd[a-z][0-9]*|/dev/hd[a-z][0-9]*)
                      device=$(printf '%s' "$canon" | sed 's/[0-9]*$//')
                      ;;
                  esac
                fi
              fi

              # This disk is the tv's only writable storage, so an absent mount is a
              # fault to report, not a "nothing to check".
              if [ -z "$device" ] || [ ! -b "$device" ]; then
                log "FAIL: ${constants.mediaMount} is not mounted, so there is no SMART data to read (''${device:-unresolved source: $src})"
                exit 1
              fi

              rc=0
              out=$(smartctl -H -A -l error "$device" 2>&1) || rc=$?
              if [ "$rc" -ne 0 ]; then
                if [ $((rc & 2)) -ne 0 ]; then
                  log "FATAL: smartctl rejected its arguments (status $rc); the check did not run"
                else
                  log "FAIL: could not read SMART from $device (status $rc): $(printf '%s' "$out" | tr '\n' ' ')"
                fi
                exit 1
              fi

              health=$(printf '%s\n' "$out" |
                awk -F': ' '/^SMART overall-health self-assessment test result:/ { print $2; exit }')

              # healthy drives report 0 for attributes they do not implement.
              zeroed=$(printf '%s\n' "$out" |
                awk '$1 ~ /^[0-9]+$/ && NF >= 10 && $7 == "Pre-fail" && $4 + 0 == 0 { printf "%s ", $2 }')

              raw() {
                printf '%s\n' "$out" |
                  awk -v id="$1" '$1 == id { for (i = 10; i <= NF; i++) if ($i ~ /^[0-9]+$/) { print $i; exit } }'
              }
              temperature=$(raw 194)
              [ -n "$temperature" ] || temperature=$(raw 190)

              summary="$device health=''${health:-unknown} reallocated=$(raw 5) pending=$(raw 197) temperature=$temperature"

              if [ "$health" != "PASSED" ] || [ -n "$zeroed" ]; then
                log "FAIL: $summary; attributes at zero: ''${zeroed:-none}"
                printf '%s\n' "$out" | logger -t hdd-disk-health
                exit 1
              else
                log "OK: $summary"
              fi
            '';
          };
        in
        {
          description = "Weekly SMART check on the data HDD, reported to the journal";
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
          OnCalendar = "Sun *-*-* 06:20:00";
          Persistent = true;
          RandomizedDelaySec = "20m";
        };
      };
    };
}
