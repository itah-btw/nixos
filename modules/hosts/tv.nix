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
      "system"
      "tv-display"
      "tv-hdd"
      "tv-openssh"
      "tv-system"
    ];
    home = [
      "identity"
      "tv-home"
    ];
  };
in
{
  flake.hostModules.tv = wiring;

  flake.nixosConfigurations.tv = mkHost {
    inherit inputs config;
    name = "tv";
    inherit wiring;
    stateVersion = "26.11";
    hardware = ../../hardware-configuration-tv.nix;

    hmImports = [ inputs.plasma-manager.homeModules.plasma-manager ];

    extra = {
      boot.loader.timeout = 2;

      networking.firewall.interfaces.${constants.lanIface}.allowedUDPPorts = [ constants.mdnsPort ];
    };
  };
}
