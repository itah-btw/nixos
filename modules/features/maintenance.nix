{ ... }:
{
  flake.modules.nixos.maintenance = { pkgs, ... }: {
    boot.loader.systemd-boot.configurationLimit = 20;

    systemd.services.nix-gc-keep-generations = {
      description = "Keep only the 20 most recent NixOS generations and garbage-collect";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "nix-gc-keep-generations" ''
          set -euo pipefail
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