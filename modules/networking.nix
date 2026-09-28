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
      # Not openFirewall: mDNS would answer LocalSend and KDE Connect queries on
      # whatever network the laptop joined. Scoped in hosts/*.nix.
      openFirewall = false;
    };
  };
}
