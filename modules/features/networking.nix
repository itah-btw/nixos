{ ... }:
{
  flake.modules.nixos.networking = { ... }: {
    networking.hostName = "nixos";
    networking.networkmanager.enable = true;

    networking.wg-quick.interfaces.vpnbook = {
      configFile = "/etc/wireguard/vpnbook.conf";
      autostart = true;
    };
  };
}
