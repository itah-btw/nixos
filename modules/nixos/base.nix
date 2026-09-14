{pkgs, ...}: {
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
