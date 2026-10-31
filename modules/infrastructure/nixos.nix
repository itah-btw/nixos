{ config, lib, ... }:
{
  # Expose each host's toplevel as a flake check so `nix flake check` evaluates
  # (and optionally builds) the full system.
  flake.checks = lib.mkMerge (
    lib.mapAttrsToList (name: nixos: {
      ${nixos.config.nixpkgs.hostPlatform.system}."nixos-${name}" = nixos.config.system.build.toplevel;
    }) config.flake.nixosConfigurations
  );
}
