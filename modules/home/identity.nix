# Home Manager identity, shared by every host: the account, its home directory
# and the HM state version. Bump stateVersion only on real upgrades, never to
# track the channel.
_: {
  flake.homeManagerModules.identity = _: {
    home.username = "itah";
    home.homeDirectory = "/home/itah";
    home.stateVersion = "26.11";
    programs.home-manager.enable = true;
  };
}
