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
          icon-theme = "Adwaita";
          font-name = "${constants.sansFont} 11";
          document-font-name = "${constants.sansFont} 11";
          monospace-font-name = "${constants.monoFont} 11";
        };
      };

      # Java AWT still needs this to map its own windows on Wayland.
      home.sessionVariables = {
        _JAVA_AWT_WM_NONREPARENTING = "1";
        EDITOR = "vis";
        NH_FLAKE = constants.root;
        # Qt6 defaults to the xdgdesktopportal theme, which ignores the
        # configured icon theme; route it through GTK settings instead.
        QT_QPA_PLATFORMTHEME = "gtk3";
      };

      xdg.userDirs = {
        enable = true;
        pictures = "${config.home.homeDirectory}/Pictures";
      };
      home.file."Pictures/Wallpapers/.keep".text = "";

      # yazi and umbriel spawn `foot` by name, so the terminal is load-bearing.
      programs.foot = {
        enable = true;
        settings = {
          main = {
            font = "${constants.monoFont}:size=11";
            pad = "0x0 center";
            include = "~/.config/foot/themes/noctalia";
          };
        };
      };

      xdg.configFile."xdg-terminals.list".text = ''
        foot.desktop
      '';
    };
}
