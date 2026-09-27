# hp: Umbriel + Noctalia laptop. One of two composition points; the wiring table
# below is the only place that says which features this host gets.
{ inputs, config, ... }:
let
  constants = config.flake.constants;
in
{
  flake.hostModules.hp = {
    nixos = [
      "boot"
      "dev-packages"
      "fingerprint"
      "keyring"
      "locale"
      "mariadb"
      "networking"
      "nix"
      "nixpkgs"
      "performance"
      "session"
      "shell"
      "syncthing"
      "system-packages"
      "user"
    ];
    home = [
      "aliases"
      "apps"
      "base"
      "cursor"
      "identity"
      "mariadb"
      "noctalia"
      "nvf"
      "shell"
      "syncthing"
      "tridactyl"
      "umbriel"
    ];
  };

  flake.nixosConfigurations.hp = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs constants;
    };
    modules = [
      # One of the two path imports in the flake; the other is in tv.nix.
      ../../hardware-configuration.nix

      inputs.umbriel.nixosModules.default
      inputs.noctalia.nixosModules.default
      inputs.noctalia-greeter.nixosModules.default
      inputs.home-manager.nixosModules.home-manager

      (_: {
        networking.hostName = "hp";
        # Tracks the release the machine was installed with, NOT the current
        # channel. Do NOT bump on upgrades.
        system.stateVersion = "26.11";

        # LocalSend (53317) and KDE Connect (1714-1764), scoped to the wifi
        # NIC: a global 53317 leaks discovery onto any network joined.
        networking.firewall.interfaces."wlan0" = {
          allowedTCPPorts = [ 53317 ];
          allowedUDPPorts = [ 53317 ];
          allowedTCPPortRanges = [
            {
              from = 1714;
              to = 1764;
            }
          ];
          allowedUDPPortRanges = [
            {
              from = 1714;
              to = 1764;
            }
          ];
        };

        home-manager = config.flake.hmDefaults // {
          extraSpecialArgs = {
            inherit inputs constants;
          };
          users.${constants.username}.imports = [
            inputs.nvf.homeManagerModules.default
            inputs.noctalia.homeModules.default
            inputs.umbriel.homeModules.default
          ]
          ++ map (n: config.flake.homeManagerModules.${n}) config.flake.hostModules.hp.home;
        };
      })
    ]
    ++ map (n: config.flake.nixosModules.${n}) config.flake.hostModules.hp.nixos;
  };
}
