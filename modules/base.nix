{
  flake.homeManagerModules.base = { config, constants, ... }: {
    # Java AWT still needs this to map its own windows on Wayland.
    home.sessionVariables = {
      _JAVA_AWT_WM_NONREPARENTING = "1";
      EDITOR = "nvim";
      NH_FLAKE = constants.root;
    };

    xdg.userDirs = {
      enable = true;
      pictures = "${config.home.homeDirectory}/Pictures";
    };
    home.file."Pictures/Wallpapers/.keep".text = "";
  };
}
