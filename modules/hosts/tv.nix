# TV host composition: the only place that wires tv modules into a system.
# Reference modules BY NAME via config.flake.*; the single path import
# (hardware-configuration-tv.nix) is the generated box hardware config,
# ported from the box when tv management moved into this flake.
# Inline blocks below are host identity (boot menu, NIC, reachability),
# following the modules/hosts/hp.nix precedent of inline firewall rules.
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

        networking.interfaces.enp2s0.wakeOnLan.enable = true;

        # Password-only until key auth is set up (see tv skill): deploys
        # and debugging go over ssh itah@192.168.0.62.
        services.openssh = {
          enable = true;
          openFirewall = true;
          settings = {
            PasswordAuthentication = true;
            PermitRootLogin = "no";
          };
        };
      }

      inputs.home-manager.nixosModules.home-manager

      # Shared core, values verified identical to the box config: Asia/
      # Jakarta + en_US + xkb us (locale), systemd-boot limit 10 + latest
      # kernel (boot), flakes + cachix + weekly GC (nix), allowUnfree
      # (nixpkgs), NetworkManager + firewall (networking), itah in
      # networkmanager/wheel (user; nix trusted status comes via wheel).
      config.flake.nixosModules.nix
      config.flake.nixosModules.nixpkgs
      config.flake.nixosModules.boot
      config.flake.nixosModules.locale
      config.flake.nixosModules.networking
      config.flake.nixosModules.user

      # TV features (ported from the box's configuration.nix/home.nix).
      config.flake.nixosModules.bigscreen
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
            config.flake.homeManagerModules.tv
          ];
        };
      }
    ];
  };
}
