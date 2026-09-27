# Syncthing, as a Home Manager service on purpose: it runs under the login user,
# the uid that owns the tv's /mnt/media, instead of a system user needing write
# access granted by hand. Peer/folder setup lives in syncthing's runtime config.
{
  flake.nixosModules.syncthing = {
    # Scoped to the NICs these two boxes sync over; a rule for an interface a
    # host lacks is inert, and a global port would listen on whatever network
    # the laptop has joined.
    networking.firewall.interfaces = {
      wlan0.allowedTCPPorts = [ 22000 ];
      enp2s0.allowedTCPPorts = [ 22000 ];
    };
  };

  flake.homeManagerModules.syncthing = {
    services.syncthing.enable = true;
  };
}
