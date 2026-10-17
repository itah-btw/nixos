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
      "fonts"
      "mariadb"
      "oxwm"
      "session"
      "system"
      "virt"
      "web"
    ];
    home = [
      "calendar"
      "clipboard"
      "desktop"
      "firefox"
      "identity"
      "mpv"
      "nvim"
      "oxwm"
      "oxwm-themes"
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

    extra = {
      networking.firewall.interfaces.${constants.wlanIface} = {
        allowedTCPPorts = [
          constants.localsendPort
        ];
        allowedUDPPorts = [
          constants.mdnsPort
          constants.localsendPort
        ];
      };
    };
  };
}
