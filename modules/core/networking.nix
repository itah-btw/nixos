# NetworkManager (iwd backend for Intel AX) + firewall + mDNS discovery
# (hostname lives in ../hosts/hp.nix).
# LocalSend ports are scoped to the wifi NIC there, not opened globally.
_: {
  flake.nixosModules.networking = {
    networking.networkmanager.wifi.backend = "iwd";
    networking.networkmanager.enable = true;
    networking.firewall.enable = true;
    # LocalSend peer discovery + printing over mDNS.
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
