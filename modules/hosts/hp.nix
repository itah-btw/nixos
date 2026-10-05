{
  inputs,
  config,
  mkHost,
  ...
}:
let
  constants = config.flake.constants;
  wiring = {
    nixos = [
      "mariadb"
      "performance"
      "session"
      "system"
      "web"
    ];
    home = [
      "desktop"
      "fastfetch"
      "identity"
      "neovim"
      "packages"
      "scripts"
      "shell"
      "tridactyl"
      "umbriel"
      "yazi"
    ];
  };
in
{
  flake.hostModules.hp = wiring;

  flake.nixosConfigurations.hp = mkHost {
    inherit inputs config;
    name = "hp";
    inherit wiring;
    stateVersion = "26.11";
    hardware = ../../hardware-configuration.nix;

    nixosImports = [
      inputs.umbriel.nixosModules.default
      inputs.noctalia.nixosModules.default
      inputs.noctalia-greeter.nixosModules.default
    ];
    hmImports = [
      inputs.noctalia.homeModules.default
      inputs.umbriel.homeModules.default
    ];

    extra = {
      networking.firewall.interfaces.${constants.wlanIface} = {
        allowedTCPPorts = [
          constants.localsendPort
          constants.httpPort
        ];
        allowedUDPPorts = [
          constants.mdnsPort
          constants.localsendPort
        ];
      };
    };
  };
}
