{
  flake.homeManagerModules.tridactyl = { pkgs, ... }: {
    programs.firefox.nativeMessagingHosts = [ pkgs.tridactyl-native ];

    # Tridactyl's auto profiledir detection targets ~/.mozilla/firefox,
    # so no pin is needed.
  };
}
