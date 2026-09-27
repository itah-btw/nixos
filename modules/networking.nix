# NetworkManager (iwd), firewall, mDNS for LocalSend and printing.
# Port scoping lives in modules/hosts/*.nix.
{
  flake.nixosModules.networking = {
    networking.networkmanager.wifi.backend = "iwd";
    networking.networkmanager.enable = true;
    networking.firewall.enable = true;
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      # Not openFirewall: that opens 5353/udp on every interface, and mDNS is
      # how LocalSend and KDE Connect are found, so it would answer their
      # queries on whatever network the laptop joined. Scoped in hosts/*.nix.
      openFirewall = false;
    };
  };
}
