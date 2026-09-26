# Home Manager session environment and well-known directories. Identity
# (username/home/stateVersion) lives in ./identity.nix.
_: {
  flake.homeManagerModules.base = { config, ... }: {
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      # Swing/Java UI (e.g. NetBeans) on Umbriel, which cannot reparent X11.
      _JAVA_AWT_WM_NONREPARENTING = "1";
      # Default editor for yazi's $EDITOR opener, git, and other tools.
      EDITOR = "nvim";
      # nh helper finds this flake without --flake every time.
      NH_FLAKE = "/etc/nixos";
    };

    # Default wallpaper browse folder when `wallpaper.directory = ""`.
    xdg.userDirs = {
      enable = true;
      pictures = "${config.home.homeDirectory}/Pictures";
    };
    home.file."Pictures/Wallpapers/.keep".text = "";
  };
}
