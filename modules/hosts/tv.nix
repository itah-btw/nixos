# TV host composition (mini-PC on unstable, KDE Big Screen).
# Same shared-repo pattern as hosts/hp.nix: reference modules BY NAME.
# Hardware file is a STUB: on the TV box, run
#   sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration-tv.nix
# and delete the placeholder below.
{ inputs, config, ... }:
{
  flake.nixosConfigurations.tv = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ../../hardware-configuration-tv.nix

      {
        networking.hostName = "tv";
        # New install on unstable now: matches hp's 26.11. Do NOT bump later.
        system.stateVersion = "26.11";
      }

      inputs.home-manager.nixosModules.home-manager

      config.flake.nixosModules.nix
      config.flake.nixosModules.nixpkgs
      config.flake.nixosModules.boot
      # LTS kernel for an appliance box (overrides latest in core/boot.nix).
      (
        { pkgs, lib, ... }:
        {
          boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
        }
      )
      config.flake.nixosModules.locale
      config.flake.nixosModules.networking
      config.flake.nixosModules.performance
      config.flake.nixosModules.user
      config.flake.nixosModules.bigscreen
      config.flake.nixosModules.shell

      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
          users.itah.imports = [
            config.flake.homeManagerModules.base
            config.flake.homeManagerModules.shell
            config.flake.homeManagerModules.aliases
          ];
        };
      }
    ];
  };
}
