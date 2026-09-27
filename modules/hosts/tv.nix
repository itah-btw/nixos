# tv: Plasma Big Screen appliance. Second composition point; see hp.nix. The
# hardware config was ported over when tv management moved into this flake.
{ inputs, config, ... }:
let
  constants = config.flake.constants;
in
{
  flake.hostModules.tv = {
    nixos = [
      "boot"
      "dev-packages"
      "locale"
      "networking"
      "nix"
      "nixpkgs"
      "syncthing"
      "tv-bigscreen"
      "tv-display"
      "tv-kodi"
      "tv-media"
      "tv-openssh"
      "tv-packages"
      "tv-power"
      "user"
    ];
    home = [
      "identity"
      "syncthing"
      "tv-home"
      "tv-kodi"
    ];
  };

  flake.nixosConfigurations.tv = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs constants;
    };
    modules = [
      # Generated, never hand-edited.
      ../../hardware-configuration-tv.nix

      inputs.home-manager.nixosModules.home-manager

      (_: {
        networking.hostName = "tv";
        # Tracks the release the machine was installed with, NOT the current
        # channel. Do NOT bump on upgrades.
        system.stateVersion = "26.11";

        # Single-boot appliance, so the menu is only for reaching an older
        # generation. Not 0: no rescue entry beats two seconds of black.
        boot.loader.timeout = 2;

        home-manager = config.flake.hmDefaults // {
          extraSpecialArgs = {
            inherit inputs constants;
          };
          users.${constants.username}.imports = [
            inputs.plasma-manager.homeModules.plasma-manager
          ]
          ++ map (n: config.flake.homeManagerModules.${n}) config.flake.hostModules.tv.home;
        };
      })
    ]
    ++ map (n: config.flake.nixosModules.${n}) config.flake.hostModules.tv.nixos;
  };
}
