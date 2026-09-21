# Home Manager base: identity, environment, well-known directories.
{ ... }:
{
  flake.homeManagerModules.base = { config, ... }: {
    home.username = "itah";
    home.homeDirectory = "/home/itah";
    home.stateVersion = "26.11";
    programs.home-manager.enable = true;

    # Wayland session env for Umbriel-started apps.
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      # Fix blank Swing/Java UI (e.g. NetBeans) on the Umbriel compositor,
      # which does not support X11 reparenting.
      _JAVA_AWT_WM_NONREPARENTING = "1";
      # Default editor for yazi's $EDITOR opener, git, and other tools.
      EDITOR = "nvim";
    };

    # Pictures dir is the default wallpaper browse folder when
    # `wallpaper.directory = ""`. Keep wallpapers here (or set an explicit
    # directory in Settings); automation picks from the resolved folder.
    xdg.userDirs = {
      enable = true;
      pictures = "${config.home.homeDirectory}/Pictures";
    };
    home.file."Pictures/Wallpapers/.keep".text = "";
  };
}
