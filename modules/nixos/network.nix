{
  flake.nixosModules.network = {
    networking.networkmanager.enable = true;
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = false;
    };
  };
}
