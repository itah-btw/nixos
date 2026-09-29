{
  flake.nixosModules.networking = {
    networking.networkmanager.wifi.backend = "iwd";
    networking.networkmanager.enable = true;
    networking.firewall.enable = true;
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = false;
    };
  };
}
