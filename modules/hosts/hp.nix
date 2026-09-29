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
      "boot"
      "identity"
      "mariadb"
      "networking"
      "nix"
      "performance"
      "security"
      "session"
      "shared-packages"
      "shell"
    ];
    home = [
      "aliases"
      "apps"
      "base"
      "cli-tools"
      "dev"
      "identity"
      "mariadb"
      "neovim"
      "noctalia"
      "scripts"
      "shell"
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
    inherit (constants) stateVersion;
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
        allowedTCPPorts = [ constants.localsendPort ];
        allowedUDPPorts = [
          constants.mdnsPort
          constants.localsendPort
        ];
      };
    };
  };
}
