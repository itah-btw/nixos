# NetworkManager + firewall (hostname lives in ../hosts/hp.nix).
# LocalSend ports are scoped to the wifi NIC there, not opened globally.
{ ... }:
{
  flake.nixosModules.networking = {
    networking.networkmanager.enable = true;
    networking.firewall.enable = true;
  };
}
