# Reachability for the tv box: sshd for deploys and debugging, and WoL so the
# box can be woken for one. Deploys run from this machine over the LAN
# (deploy-tv in ../../home/aliases.nix).
_: {
  flake.nixosModules.tv-openssh = _: {
    # WoL on the wired NIC, so a deploy does not need the box awake.
    networking.interfaces.enp2s0.wakeOnLan.enable = true;

    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        # Password is the fallback until the key below is confirmed working
        # after a real reboot; only the LAN can reach this box. Then drop it.
        PasswordAuthentication = true;
        PermitRootLogin = "no";
      };
    };

    # Per-user keys land in /etc/ssh/authorized_keys.d/. There is no top-level
    # services.openssh.authorizedKeys any more. Also present in the box's
    # ~/.ssh/authorized_keys, so a from-scratch rebuild cannot lock us out.
    users.users.itah.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIaw6LDDl480KBPXmmDpcy0jlMWMZFHCw635SvaH4HA3 itah@hp-nixos"
    ];
  };
}
