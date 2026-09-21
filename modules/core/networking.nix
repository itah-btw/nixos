# Network behavior (hostname lives with the host in ../hosts/nixos.nix).
{ ... }:
{
  flake.nixosModules.networking = {
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable networking
    networking.networkmanager.enable = true;

    # Firewall stays on; only LocalSend is punched through below.
    networking.firewall.enable = true;

    # Open ports in the firewall.
    # LocalSend: TCP + UDP 53317 (file transfer + LAN discovery).
    networking.firewall.allowedTCPPorts = [ 53317 ];
    networking.firewall.allowedUDPPorts = [ 53317 ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # networking.firewall.enable = false;
  };
}
