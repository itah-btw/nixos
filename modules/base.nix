{
  flake.homeManagerModules.base = { config, constants, ... }: {
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
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
