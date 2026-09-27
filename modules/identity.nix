# Home Manager identity. Bump stateVersion only on real upgrades.
{
  flake.homeManagerModules.identity = { constants, ... }: {
    home.username = constants.username;
    home.homeDirectory = "/home/${constants.username}";
    home.stateVersion = "26.11";
    programs.home-manager.enable = true;
  };
}
