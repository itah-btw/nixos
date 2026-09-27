# NetworkManager (iwd), firewall, mDNS for LocalSend and printing.
# Port scoping lives in modules/hosts/*.nix and syncthing.nix.
{
  flake.nixosModules.networking = {
    networking.networkmanager.wifi.backend = "iwd";
    networking.networkmanager.enable = true;
    networking.firewall.enable = true;
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      # Not openFirewall: that opens 5353/udp on every interface, and mDNS is
      # the discovery channel for LocalSend and KDE Connect, so it would answer
      # their queries on whatever network the laptop has joined -- defeating the
      # interface scoping those services' ports get in modules/hosts/*.nix. The
      # scoped 5353 rules live there for the same reason.
      openFirewall = false;
    };
  };
}
