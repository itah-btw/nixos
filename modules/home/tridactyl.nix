{
  flake.homeManagerModules.tridactyl = { config, pkgs, ... }: {
    home.file.".librewolf/native-messaging-hosts/tridactyl.json".source =
      "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";

    home.packages = [ pkgs.tridactyl-native ];

    # Tridactyl's profile detection looks under ~/.mozilla; LibreWolf keeps
    # profiles at ~/.config/librewolf/librewolf, so pin it.
    home.file.".config/tridactyl/tridactylrc".text = ''
      set profiledir ${config.home.homeDirectory}/.config/librewolf/librewolf/0h7q17ik.default
    '';
  };
}
