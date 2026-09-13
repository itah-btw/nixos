{
  config,
  pkgs,
  ...
}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Keep the boot menu short: only the latest 5 generations are bootable.
  boot.loader.systemd-boot.configurationLimit = 5;

  # Daily automatic upgrade: refresh the flake lock first (so nixpkgs actually
  # advances), then rebuild the system from /etc/nixos.
  # Manual run: `sudo systemctl start nixos-auto-upgrade` (alias: upgrade).
  systemd.services.nixos-auto-upgrade = {
    description = "Daily NixOS upgrade (flake update + rebuild)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nixos-auto-upgrade" ''
        set -eu
        export PATH=/run/current-system/sw/bin:$PATH

        notify() {
          runuser -u itah -- env DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
            notify-send -t 8000 "$@" || true
        }

        # Refresh the lock; tolerate being offline (then it's just a normal rebuild).
        old_lock=$(cut -d' ' -f1 < /etc/nixos/flake.lock | sha256sum)
        nix flake update /etc/nixos || true
        new_lock=$(cut -d' ' -f1 < /etc/nixos/flake.lock | sha256sum)

        if ! nixos-rebuild switch --flake /etc/nixos#nixos --show-trace; then
          notify -u critical "NixOS upgrade failed" "Check: journalctl -u nixos-auto-upgrade -n 50"
          exit 1
        fi

        # Auto-backup: commit + push any config changes (incl. the refreshed
        # flake.lock). Tolerate a dirty tree / being offline.
        if git -C /etc/nixos add -A && ! git -C /etc/nixos diff --cached --quiet; then
          git -C /etc/nixos commit -m "auto-upgrade: $(date '+%F %T')" || true
          git -C /etc/nixos push || true
        fi

        if [ "$old_lock" != "$new_lock" ]; then
          notify -h string:synchronous:nixos-upgrade "NixOS upgrade applied" "nixpkgs updated and system rebuilt"
        fi
      '';
    };
  };

  systemd.timers.nixos-auto-upgrade = {
    description = "Daily trigger for nixos-auto-upgrade.service";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.networkmanager.enable = true;

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

  # Faster keyboard repeat: 200ms before repeating, then 50 chars/sec.
  services.xserver.autoRepeatDelay = 200;
  services.xserver.autoRepeatInterval = 50;

  users.users."itah" = {
    isNormalUser = true;
    description = "itah";
    extraGroups = ["networkmanager" "video" "wheel"];
    packages = with pkgs; [];
  };

  # Fingerprint reader (ELAN 04f3:0c9f) via fprintd + libfprint.
  services.fprintd.enable = true;
  # Unlock with a swipe/touch on tty login, sudo, and su.
  security.pam.services.login.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.su.fprintAuth = true;

  environment.systemPackages = with pkgs; [
    alejandra
    brightnessctl
    git
    neovim
    opencode
    proton-vpn-cli
    proton-vpn
    python3
    wget
    wireplumber
  ];
}
