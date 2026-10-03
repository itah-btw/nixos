{
  flake.homeManagerModules.desktop =
    {
      config,
      constants,
      pkgs,
      ...
    }:
    {
      home.pointerCursor = {
        enable = true;
        package = pkgs.bibata-cursors;
        name = constants.cursorTheme;
        size = constants.cursorSize;
        gtk.enable = true;
      };

      gtk.enable = true;
      gtk.theme = {
        package = pkgs.adw-gtk3;
        name = "adw-gtk3";
      };
      gtk.iconTheme = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
      };

      dconf = {
        enable = true;
        settings."org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          font-name = "${constants.sansFont} 11";
          document-font-name = "${constants.sansFont} 11";
          monospace-font-name = "${constants.monoFont} 11";
        };
      };

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

      # yazi and umbriel spawn `kitty` by name, so the terminal is load-bearing.
      programs.kitty = {
        enable = true;
        settings = {
          font_family = constants.monoFont;
          cursor_trail = 1;
          background_opacity = 1.0;
        };
        extraConfig = ''
          include themes/noctalia.conf
        '';
      };

      xdg.configFile."xdg-terminals.list".text = ''
        kitty.desktop
      '';
    };
}
