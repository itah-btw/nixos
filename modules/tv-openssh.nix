# sshd for deploys, plus WoL. No passwordless sudo rule, and one could not be
# scoped: activating a closure runs its code as root. See README.md.
{
  flake.nixosModules.tv-openssh = { constants, ... }: {
    networking.interfaces.enp2s0.wakeOnLan.enable = true;

    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        # Key-only. The key lands in authorizedKeys below, so the deploy is what
        # makes it work -- verify with `ssh tv true`.
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Also in the box's own authorized_keys, so a from-scratch rebuild cannot lock
    # us out.
    users.users.${constants.username}.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIaw6LDDl480KBPXmmDpcy0jlMWMZFHCw635SvaH4HA3 itah@hp-nixos"
    ];
  };
}
