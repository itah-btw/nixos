{
  flake.nixosModules.networking = {
    # noctalia's `recommendedServices` also provides NetworkManager on hp. This
    # line is the only one that reaches tv, which runs no noctalia.
    networking.networkmanager.enable = true;
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = false;
    };
  };
}
