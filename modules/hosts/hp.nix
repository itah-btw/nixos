# Host composition (the only place that wires modules into a system).
#
# Dendritic rule: reference modules BY NAME via config.flake.* (never by
# file path), so feature files can be moved/renamed freely. The single
# path import below (hardware-configuration.nix) is the sanctioned
# exception: it is a generated file, not a feature module.
{ inputs, config, ... }:
{
  flake.nixosConfigurations.hp = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # Generated hardware scan (do not hand-edit that file).
      ../../hardware-configuration.nix

      # Host identity (stays with the host, not in reusable features).
      {
        networking.hostName = "hp";
        # See `man configuration.nix` / NixOS manual before changing:
        # this tracks the release the machine was installed with, NOT the
        # current channel. Do NOT bump on upgrades.
        system.stateVersion = "26.11";
      }

      # Project modules (each disables its nixpkgs counterpart
      # internally, so there is no conflict).
      inputs.umbriel.nixosModules.default
      inputs.noctalia.nixosModules.default
      inputs.noctalia-greeter.nixosModules.default

      inputs.home-manager.nixosModules.home-manager

      # First-party NixOS features, composed by name.
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

      # Home Manager (NixOS module). User dotfiles live in
      # flake.homeManagerModules.*, composed by name here.
      # EXCEPT Noctalia theming (theme/wallpaper/templates/palettes) which
      # stays runtime-managed so wallpaper-derived palettes + wallpaper
      # automation rotation keep working (see home/noctalia.nix).
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
