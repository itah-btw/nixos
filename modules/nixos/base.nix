{pkgs, ...}: let
  # USB storage notifications. Not run directly by udev (long-running DBus work); udev
  # launches it via `systemd-run` so it can't block the device event handling.
  usbNotify = pkgs.writeShellScript "usb-notify" ''
    set -u
    action="$1"
    k="$2" # kernel device name, e.g. sdb
    STATEDIR=/run/nixos-usb
    mkdir -p "$STATEDIR"
    notify() {
      runuser -u itah -- env DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
        notify-send "$@" || true
    }
    case "$action" in
      add)
        name="$ID_VENDOR $ID_MODEL"
        [ -n "$ID_VENDOR" ] && [ -n "$ID_MODEL" ] || name="USB storage"
        printf '%s\n' "$name" > "$STATEDIR/$k"
        notify -t 4000 -h string:synchronous:usb -i drive-removable-media "USB" "$name connected"
        ;;
      remove)
        name=$(cat "$STATEDIR/$k" 2>/dev/null || true)
        [ -n "$name" ] || name="USB storage"
        rm -f "$STATEDIR/$k"
        notify -t 4000 -h string:synchronous:usb -i drive-removable-media "USB" "$name disconnected"
        ;;
    esac
  '';
in {
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Daily nixpkgs update check (notify only — no lock change, no rebuild).
  systemd.services.nixos-check-updates = {
    description = "Daily nixpkgs update check (notify only)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nixos-check-updates" ''
        set -u
        export PATH=/run/current-system/sw/bin:$PATH
        notify() {
          runuser -u itah -- env DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
            notify-send -t 8000 "$@" || true
        }

        # Locked nixpkgs revision from flake.lock.
        cur=$(nix flake metadata /etc/nixos --json 2>/dev/null | python3 -c '
        import json, sys
        try:
            print(json.load(sys.stdin)["locks"]["nodes"]["nixpkgs"]["locked"].get("rev", ""))
        except Exception:
            print("")' 2>/dev/null)

        # Newest nixpkgs revision on the branch (network fetch, lock untouched).
        meta=$(nix flake metadata github:NixOS/nixpkgs/nixos-unstable --json 2>/dev/null) || exit 0
        new=$(printf '%s' "$meta" | python3 -c '
        import json, sys
        try:
            print(json.load(sys.stdin)["locked"]["rev"])
        except Exception:
            pass' 2>/dev/null)

        [ -n "$cur" ] && [ -n "$new" ] && [ "$cur" != "$new" ] || exit 0
        notify -h string:synchronous:nixos-updates "New nixpkgs available" \
          "unstable $(echo "$new" | cut -c1-8) vs yours $(echo "$cur" | cut -c1-8). Run 'update' then 'rebuild' to apply."
      '';
    };
  };

  systemd.timers.nixos-check-updates = {
    description = "Daily trigger for nixos-check-updates.service";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };

  # Manual upgrade: update lock + rebuild + notify (run: `sudo systemctl start nixos-upgrade`).
  systemd.services.nixos-upgrade = {
    description = "Manual NixOS upgrade (flake update + rebuild)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nixos-upgrade" ''
        set -eu
        export PATH=/run/current-system/sw/bin:$PATH
        notify() {
          runuser -u itah -- env DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
            notify-send -t 8000 "$@" || true
        }

        nix flake update /etc/nixos || true
        git -C /etc/nixos add -A || true
        if ! nixos-rebuild switch --flake /etc/nixos#nixos --show-trace; then
          notify -u critical "NixOS upgrade failed" "Check: journalctl -u nixos-upgrade -n 50"
          exit 1
        fi
        notify -h string:synchronous:nixos-upgrade "NixOS upgrade applied" "system rebuilt"
      '';
    };
  };

  # Weekly backup: commit + push /etc/nixos to GitHub.
  systemd.services.nixos-git-push = {
    description = "Weekly config commit + push to GitHub";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nixos-git-push" ''
        set -eu
        export PATH=/run/current-system/sw/bin:$PATH
        if git -C /etc/nixos add -A && ! git -C /etc/nixos diff --cached --quiet; then
          git -C /etc/nixos commit -m "weekly sync: $(date '+%F %T')"
        fi
        git -C /etc/nixos push || true
      '';
    };
  };

  systemd.timers.nixos-git-push = {
    description = "Weekly trigger for nixos-git-push.service";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "Mon *-*-* 04:00:00";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };

  # ── Event notifications ──────────────────────────────────────────────────────
  # All scripts use the same notify() helper pattern as the services above:
  # root-by-default systemd timers/udev/NM talk to the user session DBus directly.

  # Battery + AC power: warns at 20/10/5% and on plug/unplug (60s poll, upower).
  systemd.services.nixos-battery-monitor = {
    description = "Battery and AC power notifications";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nixos-battery-monitor" ''
        set -u
        export PATH=/run/current-system/sw/bin:$PATH
        STATE=/run/nixos-battery
        notify() {
          runuser -u itah -- env DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
            notify-send "$@" || true
        }

        [ -e /run/user/1000/bus ] || exit 0
        dpath=$(upower -e 2>/dev/null | grep '/devices/battery_' | head -n1)
        [ -n "$dpath" ] || exit 0
        state=$(upower -i "$dpath" | sed -n 's/^[[:space:]]*state:[[:space:]]*//p')
        pct=$(upower -i "$dpath" | sed -n 's/^[[:space:]]*percentage:[[:space:]]*//p' | tr -dc '0-9')
        [ -n "$pct" ] || exit 0

        case "$state" in
          charging|fully-charged|pending-charge) cur=ac ;;
          *) cur=bat ;;
        esac

        prev_mode=unknown
        prev_last=999
        [ -f "$STATE" ] && read -r prev_mode prev_last < "$STATE"
        LAST=$prev_last

        if [ "$cur" != "$prev_mode" ]; then
          LAST=999
          if [ "$prev_mode" != unknown ]; then
            if [ "$cur" = ac ]; then
              notify -t 5000 -i battery-full-charging -h int:value:$pct \
                -h string:synchronous:power "AC power" "Plugged in - charging ($pct%)"
            else
              notify -t 5000 -i battery-caution -h int:value:$pct \
                -h string:synchronous:power "On battery" "Unplugged - at $pct%"
            fi
          fi
        fi

        if [ "$cur" = bat ]; then
          if [ "$pct" -le 5 ]; then
            lvl=5
          elif [ "$pct" -le 10 ]; then
            lvl=10
          elif [ "$pct" -le 20 ]; then
            lvl=20
          else
            lvl=999
          fi
          if [ "$lvl" -lt "$LAST" ] && [ "$lvl" -le 20 ]; then
            if [ "$lvl" -le 5 ]; then
              notify -u critical -i battery-empty -h int:value:$pct \
                -h string:synchronous:power "Battery critical" "Only $pct% left - plug in now"
            elif [ "$lvl" -le 10 ]; then
              notify -u critical -i battery-caution -h int:value:$pct \
                -h string:synchronous:power "Battery low" "$pct% remaining - plug in soon"
            else
              notify -t 8000 -i battery-caution -h int:value:$pct \
                -h string:synchronous:power "Battery warning" "$pct% remaining"
            fi
            LAST=$lvl
          fi
        fi

        printf '%s %s\n' "$cur" "$LAST" > "$STATE"
      '';
    };
  };

  systemd.timers.nixos-battery-monitor = {
    description = "60s trigger for the battery monitor";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "90s";
      OnUnitActiveSec = "60s";
    };
  };

  # Bluetooth device connect/disconnect (10s poll, bluez). Silently resets on
  # adapter power-off so toggling BT off doesn't spam "device disconnected".
  systemd.services.nixos-bluetooth-monitor = {
    description = "Bluetooth device notifications";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nixos-bluetooth-monitor" ''
        set -u
        export PATH=/run/current-system/sw/bin:$PATH
        STATEDIR=/run/nixos-bluetooth
        LIST=$STATEDIR/devices
        mkdir -p "$STATEDIR"
        notify() {
          runuser -u itah -- env DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
            notify-send "$@" || true
        }

        [ -e /run/user/1000/bus ] || exit 0
        if ! bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
          rm -f "$LIST"
          exit 0
        fi

        bluetoothctl devices Connected 2>/dev/null | awk '{print $2}' | sort -u > "$STATEDIR/current"
        : > "$STATEDIR/previous"
        [ -f "$LIST" ] && cp "$LIST" "$STATEDIR/previous"

        added=$(comm -13 "$STATEDIR/previous" "$STATEDIR/current")
        removed=$(comm -23 "$STATEDIR/previous" "$STATEDIR/current")
        for mac in $added; do
          name=$(bluetoothctl info "$mac" 2>/dev/null | sed -n 's/.*Name:[[:space:]]*//p' | head -n1)
          [ -n "$name" ] || name=$mac
          notify -t 5000 -i bluetooth -h string:synchronous:bluetooth "Bluetooth" "$name connected"
        done
        for mac in $removed; do
          name=$(bluetoothctl info "$mac" 2>/dev/null | sed -n 's/.*Name:[[:space:]]*//p' | head -n1)
          [ -n "$name" ] || name=$mac
          notify -t 5000 -i bluetooth -h string:synchronous:bluetooth "Bluetooth" "$name disconnected"
        done

        cp "$STATEDIR/current" "$LIST"
      '';
    };
  };

  systemd.timers.nixos-bluetooth-monitor = {
    description = "10s trigger for the bluetooth device monitor";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "45s";
      OnUnitActiveSec = "10s";
    };
  };

  # Disk space: daily, warns at ≥90% and is critical ≥97% (real filesystems only).
  systemd.services.nixos-disk-monitor = {
    description = "Disk space notifications";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nixos-disk-monitor" ''
        set -u
        set -f
        export PATH=/run/current-system/sw/bin:$PATH
        STATEDIR=/run/nixos-disk
        mkdir -p "$STATEDIR"
        notify() {
          runuser -u itah -- env DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
            notify-send "$@" || true
        }

        [ -e /run/user/1000/bus ] || exit 0
        df -P -T 2>/dev/null | awk 'NR>1 && $2 ~ /^(ext4|xfs|btrfs|zfs|ntfs|vfat|exfat|f2fs)$/ {
          u=$6; sub(/%/,"",u); if (u+0>=90) print $7, $2, u
        }' | while read -r mount fstype used; do
          key=$(printf '%s' "$mount" | tr '/' '_')
          prev=0
          [ -f "$STATEDIR/$key" ] && prev=$(cat "$STATEDIR/$key")
          if [ "$used" -ge 97 ]; then
            notify -u critical -h string:synchronous:disk "Disk almost full" "$mount ($fstype): $used% used"
          elif [ "$used" -ge 90 ] && [ "$used" -gt "$prev" ]; then
            notify -t 8000 -h string:synchronous:disk "Disk getting full" "$mount ($fstype): $used% used"
          fi
          if [ "$used" -ge 90 ]; then
            printf '%s\n' "$used" > "$STATEDIR/$key"
          else
            rm -f "$STATEDIR/$key"
          fi
        done
      '';
    };
  };

  systemd.timers.nixos-disk-monitor = {
    description = "Daily trigger for the disk monitor";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };

  # Firmware: weekly metadata refresh + update check; only notifies when the
  # available-update set actually changed (dedupe via content hash).
  systemd.services.nixos-fwupd-check = {
    description = "Weekly firmware update check + notify";
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = 300;
      ExecStart = pkgs.writeShellScript "nixos-fwupd-check" ''
        set -u
        export PATH=/run/current-system/sw/bin:$PATH
        STATEDIR=/run/nixos-fwupd
        mkdir -p "$STATEDIR"
        notify() {
          runuser -u itah -- env DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
            notify-send "$@" || true
        }

        [ -e /run/user/1000/bus ] || exit 0
        timeout 240 fwupdmgr refresh >/dev/null 2>&1 || true
        out=$(timeout 60 fwupdmgr get-updates 2>&1) || true
        case "$out" in
          *No\ updates*|*No\ upgradable*|*No\ results*|*Metadata\ is\ up\ to\ date*|"") exit 0 ;;
        esac

        stamp=$(printf '%s' "$out" | sed 's/[0-9]//g' | cksum | awk '{print $1}')
        prev=
        [ -f "$STATEDIR/prev" ] && prev=$(cat "$STATEDIR/prev")
        [ -n "$prev" ] && [ "$prev" = "$stamp" ] && exit 0

        n=$(printf '%s' "$out" | grep -c 'Update Version' || true)
        body=$(printf '%s' "$out" | grep -E 'Update Version|^[[:space:]]*•' | head -n 6)
        [ -n "$body" ] || body="Run fwupdmgr update to review."
        summary="Firmware updates available"
        [ "$n" -gt 0 ] 2>/dev/null && summary="Firmware updates available ($n)"

        notify -h string:synchronous:fwupd "Firmware updates" "$body"
        printf '%s' "$stamp" > "$STATEDIR/prev"
      '';
    };
  };

  systemd.timers.nixos-fwupd-check = {
    description = "Weekly trigger for the firmware update check";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "Wed *-*-* 03:30:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };

  # USB storage plug/unplug (udev → systemd-run, non-blocking).
  # `DEVTYPE=="disk"` is rejected by new systemd udev; KERNEL=="sd[a-z]" matches
  # whole USB disks only (not their partitions — which also avoids per-partition spam).
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ENV{ID_BUS}=="usb", RUN+="${pkgs.systemd}/bin/systemd-run --no-block --collect ${usbNotify} add %k"
    ACTION=="remove", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ENV{ID_BUS}=="usb", RUN+="${pkgs.systemd}/bin/systemd-run --no-block --collect ${usbNotify} remove %k"
  '';

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # zstd-compressed RAM swap (reduces SSD wear under memory pressure).
  zramSwap.enable = true;

  services.smartd.enable = true; # NVMe/SATA health monitoring

  # PipeWire with ALSA/Pulse compat, WirePlumber session manager, rtkit for realtime prio.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # Laptop: ACPI power management, Intel thermald, HP firmware updates, TLP battery tuning.
  powerManagement.enable = true;
  services.thermald.enable = true;
  services.fwupd.enable = true;
  services.tlp.enable = true;

  networking.networkmanager.enable = true;

  # Quad9 over strict DoT, globally (fails closed; `*.lan` names won't resolve — expected).
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = [
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
        "2620:fe::fe#dns.quad9.net"
        "2620:fe::9#dns.quad9.net"
      ];
      DNSOverTLS = "strict";
    };
  };

  # Quad9 per-link too: NM installs DHCP (router) DNS per interface, which resolved
  # prefers over global. VPN links are exempt so ProtonVPN DNS wins while the tunnel is up.
  networking.networkmanager.dispatcherScripts = [
    {
      type = "basic";
      source = pkgs.writeText "force-quad9-dns" ''
        case "$2" in
          up|dhcp4-change|dhcp6-change) ;;
          *) exit 0 ;;
        esac
        case "$DEVICE_IFACE" in
          wl*|en*|eth*|usb*) ;;
          *) exit 0 ;;
        esac
        /run/current-system/sw/bin/resolvectl dns "$DEVICE_IFACE" \
          9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net \
          2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net
        /run/current-system/sw/bin/resolvectl dnsovertls "$DEVICE_IFACE" strict
      '';
    }
    # Connect/disconnect notifications (all actions, user-notified).
    {
      type = "basic";
      source = pkgs.writeText "nm-notify" ''
        #!/bin/sh
        action="$2"
        [ -e /run/user/1000/bus ] || exit 0
        notify() {
          runuser -u itah -- env DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
            notify-send "$@" || true
        }
        case "$action" in
          up)
            [ -z "$CONNECTION_ID" ] && exit 0
            notify -t 4000 -i network-wireless -h string:synchronous:network "Network" "Connected to $CONNECTION_ID"
            ;;
          down)
            [ -z "$CONNECTION_ID" ] && exit 0
            notify -t 6000 -i network-offline -h string:synchronous:network "Network" "$CONNECTION_ID disconnected"
            ;;
          vpn-up)
            if [ -n "$CONNECTION_ID" ]; then
              notify -t 5000 -i network-vpn -h string:synchronous:network "VPN" "Connected: $CONNECTION_ID"
            else
              notify -t 5000 -i network-vpn -h string:synchronous:network "VPN" "Connected"
            fi
            ;;
          vpn-down)
            notify -t 5000 -u critical -i network-offline -h string:synchronous:network "VPN" "Disconnected"
            ;;
        esac
      '';
    }
  ];

  security.sudo.execWheelOnly = true;

  # UPower DBus API for WirePlumber + desktop widgets (avoids repeated UPower errors).
  services.upower.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  time.timeZone = "Asia/Jakarta";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  console.useXkbConfig = true; # match the Linux console keymap to X

  # Faster keyboard repeat: 200ms delay, 50 chars/sec.
  services.xserver.autoRepeatDelay = 200;
  services.xserver.autoRepeatInterval = 50;

  users.users.itah = {
    isNormalUser = true;
    description = "itah";
    extraGroups = ["networkmanager" "video" "wheel"];
  };

  services.fprintd.enable = true; # ELAN fingerprint reader
  # Swipe to unlock on tty login, sudo, and su.
  security.pam.services.login.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.su.fprintAuth = true;

  environment.systemPackages = with pkgs; [
    alejandra
    brightnessctl
    git
    neovim
    opencode
    proton-vpn
    python3
    wget
    wireplumber
  ];
}
