# Everyday apps: git, kitty, GTK appearance, zoxide. Per-app configs that earn
# their own file: yazi.nix, tridactyl.nix. Aliases: aliases.nix.
{
  flake.homeManagerModules.apps = { pkgs, ... }: {
    programs.git = {
      enable = true;
      settings = {
        user.name = "itah";
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
        font_family = "JetBrainsMono Nerd Font";
        cursor_trail = 1;
        # Opacity lives in Umbriel's window rules, so keep this opaque.
        background_opacity = 1.0;
      };
      # Noctalia writes themes/noctalia.conf at runtime; apply.sh cannot edit
      # the read-only symlink, so the include has to be declared here.
      extraConfig = ''
        include themes/noctalia.conf
      '';
    };

    # GTK appearance. gtk.enable writes settings.ini; Noctalia's gtk.css
    # templates layer on top and keep working because they leave it alone.
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
        # prefer-dark lives in dconf, not settings.ini, so Noctalia's GTK
        # templates keep owning that file.
        color-scheme = "prefer-dark";
        font-name = "Inter 11";
        document-font-name = "Inter 11";
        monospace-font-name = "JetBrainsMono Nerd Font 11";
      };
    };

    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };

    # kitty and zoxide come from their programs.*.enable above.
    home.packages = with pkgs; [
      firefox

      # Also in tv-packages.nix: used from hp too, not just the TV. 184 MiB of
      # closure, nearly all webkitgtk+abi=6.0, which only stremio pulls in.
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
