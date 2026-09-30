{
  flake.nixosModules.identity = { constants, ... }: {
    time.timeZone = constants.timeZone;
    i18n.defaultLocale = constants.locale;
    users.users.${constants.username} = {
      isNormalUser = true;
      description = constants.username;
      # audio/video/input come from logind's uaccess ACL while a seat session is
      # attached; the groups are what make a script or `systemd --user` unit
      # without one work too.
      extraGroups = [
        "audio"
        "input"
        "lp"
        "networkmanager"
        "render"
        "video"
        "wheel"
      ];
    };
    security.sudo.wheelNeedsPassword = true;
  };

  flake.homeManagerModules.identity = { constants, ... }: {
    home.username = constants.username;
    home.homeDirectory = "/home/${constants.username}";
    programs.home-manager.enable = true;
  };
}
