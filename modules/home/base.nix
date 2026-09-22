# Home Manager base: identity, environment, well-known directories.
{ ... }:
{
  flake.homeManagerModules.base = { config, ... }: {
    home.username = "itah";
    home.homeDirectory = "/home/itah";
    home.stateVersion = "26.11";
    programs.home-manager.enable = true;

    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      # Swing/Java UI (e.g. NetBeans) on Umbriel, which cannot reparent X11.
      _JAVA_AWT_WM_NONREPARENTING = "1";
      # Default editor for yazi's $EDITOR opener, git, and other tools.
      EDITOR = "nvim";
    };

    # Default wallpaper browse folder when `wallpaper.directory = ""`.
    xdg.userDirs = {
      enable = true;
      pictures = "${config.home.homeDirectory}/Pictures";
    };
    home.file."Pictures/Wallpapers/.keep".text = "";
  };
}
