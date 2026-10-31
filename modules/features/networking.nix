_: {
  flake.modules.nixos.networking = _: {
    networking = {
      hostName = "nixos";
      networkmanager.enable = true;

      wg-quick.interfaces.vpnbook = {
        configFile = "/etc/wireguard/vpnbook.conf";
        autostart = false;
      };
    };
  };
}
