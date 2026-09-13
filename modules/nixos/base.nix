{
  config,
  pkgs,
  ...
}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Keep the boot menu short: only the latest 5 generations are bootable.
  boot.loader.systemd-boot.configurationLimit = 5;

  # No auto-upgrade. Daily: just check whether nixpkgs has a newer revision and
  # notify itah (no lock change, no rebuild). Manual upgrade: `sudo systemctl
  # start nixos-upgrade` (alias: upgrade) or `update`+`rebuild`.
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

        # Locked nixpkgs revision in /etc/nixos/flake.lock.
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

  # Manual upgrade (update lock + rebuild + notify). No longer automatic.
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
        if ! nixos-rebuild switch --flake /etc/nixos#nixos --show-trace; then
          notify -u critical "NixOS upgrade failed" "Check: journalctl -u nixos-upgrade -n 50"
          exit 1
        fi
        notify -h string:synchronous:nixos-upgrade "NixOS upgrade applied" "system rebuilt"
      '';
    };
  };

  # Weekly config backup: commit + push /etc/nixos to GitHub (manual run:
  # `sudo systemctl start nixos-git-push`). Keeps flake.lock and edits backed
  # up on a stable cadence without pushing after every rebuild.
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
