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
      "oxwm"
      "session"
      "system"
      "virt"
      "web"
    ];
    home = [
      "desktop"
      "fastfetch"
      "identity"
      "nvim"
      "oxwm"
      "packages"
      "scripts"
      "shell"
      "tridactyl"
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

    nixosImports = [ ];
    hmImports = [ ];

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
