{
  flake.homeManagerModules.apps = { constants, pkgs, ... }: {
    home.pointerCursor = {
      enable = true;
      package = pkgs.bibata-cursors;
      name = constants.cursorTheme;
      size = constants.cursorSize;
      gtk.enable = true;
      x11.enable = true;
    };
    home.file.".mozilla/native-messaging-hosts/tridactyl.json".source =
      "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";
    programs.git = {
      enable = true;
      settings = {
        user.name = constants.username;
        user.email = "103980435+itah-btw@users.noreply.github.com";
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        commit.verbose = true;
      };
    };

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

    gtk.enable = true;
    gtk.theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3";
    };
    gtk.iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };

    xdg.configFile."xdg-terminals.list".text = ''
      kitty.desktop
    '';

    dconf = {
      enable = true;
      settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        font-name = "${constants.sansFont} 11";
        document-font-name = "${constants.sansFont} 11";
        monospace-font-name = "${constants.monoFont} 11";
      };
    };

    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };

    home.packages = with pkgs; [
      firefox
      tridactyl-native
      stremio-linux-shell
      proton-authenticator
      proton-vpn
      libreoffice
      zathura
      obs-studio
      imv
      mpv
      netbeans
      localsend
      llama-cpp
      lutgen
    ];
  };
}
