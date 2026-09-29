{
  flake.nixosModules.identity = { constants, ... }: {
    time.timeZone = constants.timeZone;
    i18n.defaultLocale = constants.locale;
    users.users.${constants.username} = {
      isNormalUser = true;
      description = constants.username;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
    security.sudo.wheelNeedsPassword = true;
  };

  flake.homeManagerModules.identity = { constants, ... }: {
    home.username = constants.username;
    home.homeDirectory = "/home/${constants.username}";
    home.stateVersion = constants.stateVersion;
    programs.home-manager.enable = true;
  };
}
