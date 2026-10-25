{ ... }:
{
  flake.modules.nixos.maintenance = { pkgs, ... }: {
    # Keep only the 20 most recent system generations in the boot menu.
    boot.loader.systemd-boot.configurationLimit = 20;

    systemd.services.nix-gc-keep-generations = {
      description = "Keep only the 20 most recent NixOS generations and garbage-collect";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "nix-gc-keep-generations" ''
          set -euo pipefail
          # Keep the last 10 generations of the system profile (+10),
          # along with any newer than the current one.
          ${pkgs.nix}/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations +20
          ${pkgs.nix}/bin/nix-collect-garbage
        '';
      };
    };

    systemd.timers.nix-gc-keep-generations = {
      description = "Weekly cleanup of old NixOS generations";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}