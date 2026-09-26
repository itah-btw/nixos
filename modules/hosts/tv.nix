# TV host composition: the only place that wires tv modules into a system.
# Reference modules BY NAME via config.flake.*; the single path import
# (hardware-configuration-tv.nix) is the generated box hardware config,
# ported from the box when tv management moved into this flake.
# The inline block below is host identity only, following the
# modules/hosts/hp.nix precedent.
{ inputs, config, ... }:
{
  flake.nixosConfigurations.tv = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ../../hardware-configuration-tv.nix

      {
        networking.hostName = "tv";
        # Tracks the release the machine was installed with, NOT the
        # current channel. Do NOT bump on upgrades.
        system.stateVersion = "26.11";

        # Single-boot appliance, so the menu is only ever needed to fall
        # back to an older generation. 2s is enough to reach that; not 0,
        # because a boot with no way to pick a rescue entry is a worse
        # outcome than two seconds of black.
        boot.loader.timeout = 2;
      }

      inputs.home-manager.nixosModules.home-manager

      # Shared core (nix, nixpkgs, boot, locale, networking, user); the values
      # were verified identical to the box's own config before the move.
      config.flake.nixosModules.nix
      config.flake.nixosModules.nixpkgs
      config.flake.nixosModules.boot
      config.flake.nixosModules.locale
      config.flake.nixosModules.networking
      config.flake.nixosModules.user

      config.flake.nixosModules.tv-bigscreen
      config.flake.nixosModules.tv-openssh
      config.flake.nixosModules.tv-power
      config.flake.nixosModules.tv-media
      config.flake.nixosModules.tv-display
      config.flake.nixosModules.tv-packages

      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
          users.itah.imports = [
            inputs.plasma-manager.homeModules.plasma-manager
            config.flake.homeManagerModules.identity
            config.flake.homeManagerModules.tv
          ];
        };
      }
    ];
  };
}
