{
  flake.homeManagerModules.desktop = { constants, pkgs, ... }: {
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
  };
}
