# Host composition: the only place that wires modules into a system.
# Reference modules BY NAME via config.flake.*; the single path import
# (hardware-configuration.nix) is generated, not a feature module.
{ inputs, config, ... }:
{
  flake.nixosConfigurations.hp = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ../../hardware-configuration.nix

      {
        networking.hostName = "hp";
        # Tracks the release the machine was installed with, NOT the
        # current channel. Do NOT bump on upgrades.
        system.stateVersion = "26.11";

        # LocalSend: TCP + UDP 53317, scoped to the wifi NIC only
        # (globally-open 53317 leaks discovery on untrusted networks).
        networking.firewall.interfaces."wlp0s20f3" = {
          allowedTCPPorts = [ 53317 ];
          allowedUDPPorts = [ 53317 ];
        };
      }

      inputs.umbriel.nixosModules.default
      inputs.noctalia.nixosModules.default
      inputs.noctalia-greeter.nixosModules.default

      inputs.home-manager.nixosModules.home-manager

      config.flake.nixosModules.nix
      config.flake.nixosModules.nixpkgs
      config.flake.nixosModules.boot
      config.flake.nixosModules.locale
      config.flake.nixosModules.networking
      config.flake.nixosModules.performance
      config.flake.nixosModules.user
      config.flake.nixosModules.system-packages
      config.flake.nixosModules.session
      config.flake.nixosModules.keyring
      config.flake.nixosModules.fingerprint
      config.flake.nixosModules.mariadb
      config.flake.nixosModules.shell

      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
          users.itah.imports = [
            inputs.nvf.homeManagerModules.default
            inputs.noctalia.homeModules.default
            inputs.umbriel.homeModules.default

            config.flake.homeManagerModules.base
            config.flake.homeManagerModules.umbriel
            config.flake.homeManagerModules.noctalia
            config.flake.homeManagerModules.apps
            config.flake.homeManagerModules.aliases
            config.flake.homeManagerModules.tridactyl
            config.flake.homeManagerModules.cursor
            config.flake.homeManagerModules.nvf
            config.flake.homeManagerModules.mariadb
            config.flake.homeManagerModules.shell
          ];
        };
      }
    ];
  };
}
