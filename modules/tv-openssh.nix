{
  flake.nixosModules.tv-openssh = { constants, ... }: {
    networking.interfaces.${constants.lanIface}.wakeOnLan.enable = true;

    services.openssh = {
      enable = true;
      openFirewall = false;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    networking.firewall.interfaces.${constants.lanIface}.allowedTCPPorts = [ constants.sshPort ];

    users.users.${constants.username}.openssh.authorizedKeys.keys = [ constants.sshKey ];
  };
}
