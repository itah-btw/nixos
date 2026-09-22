# Everyday apps + their dotfiles. Shell aliases live in ./aliases.nix.
{ ... }:
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
        cursor_trail = 3;
        # Glass terminal over the Umbriel window blur.
        background_opacity = 0.85;
        background_blur = 30;
      };
      # Noctalia writes themes/noctalia.conf at runtime; this include is the
      # declarative half (kitty.conf is a read-only store symlink, so
      # apply.sh cannot add it itself).
      extraConfig = ''
        include themes/noctalia.conf
      '';
    };

    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      shellWrapperName = "y";
      extraPackages = with pkgs; [
        zip
        unzip
        p7zip
        zstd
      ];
      plugins = {
        compress = pkgs.yaziPlugins.compress;
      };
      keymap = {
        mgr.prepend_keymap = [
          {
            on = [
              "c"
              "a"
              "a"
            ];
            run = "plugin compress";
            desc = "Archive selected files";
          }
          {
            on = [
              "c"
              "a"
              "p"
            ];
            run = "plugin compress -p";
            desc = "Archive selected files (password)";
          }
          {
            on = [
              "c"
              "x"
            ];
            run = "shell -- ya pub extract --list %s";
            desc = "Extract selected archives here";
          }
        ];
      };
      settings = {
        opener = {
          zathura = [
            {
              run = "zathura %s";
              desc = "Open with Zathura";
              for = "linux";
              orphan = true;
            }
          ];
          imv-dir = [
            {
              run = "imv-dir %s";
              desc = "Open with imv-dir";
              for = "linux";
              orphan = true;
            }
          ];
          mpv = [
            {
              run = "mpv %s";
              desc = "Open with mpv";
              for = "linux";
              orphan = true;
            }
          ];
          firefox = [
            {
              run = "firefox %s";
              desc = "Open in Firefox";
              for = "linux";
              orphan = true;
            }
          ];
          libreoffice = [
            {
              run = "libreoffice %s";
              desc = "Open with LibreOffice";
              for = "linux";
              orphan = true;
            }
          ];
          nvim = [
            {
              run = "nvim %s";
              desc = "Open in Neovim";
              for = "linux";
              block = true;
            }
          ];
        };
        open.prepend_rules = [
          # Text / code
          {
            mime = "text/*";
            use = [
              "nvim"
              "edit"
            ];
          }
          {
            mime = "application/{json,ndjson,javascript,wine-extension-ini}";
            use = [
              "nvim"
              "edit"
            ];
          }
          # Documents
          {
            mime = "application/{pdf,djvu}";
            use = [
              "zathura"
              "open"
            ];
          }
          {
            mime = "{application/epub+zip,application/vnd.comicbook+zip}";
            use = [
              "zathura"
              "open"
            ];
          }
          # Office
          {
            mime = "application/{msword,vnd.ms-excel,vnd.ms-powerpoint,vnd.openxmlformats-officedocument.wordprocessingml.document,vnd.openxmlformats-officedocument.spreadsheetml.sheet,vnd.openxmlformats-officedocument.presentationml.presentation,vnd.oasis.opendocument.*}";
            use = [
              "libreoffice"
              "open"
            ];
          }
          # Images
          {
            mime = "image/*";
            use = [
              "imv-dir"
              "open"
            ];
          }
          # Media
          {
            mime = "{audio,video}/*";
            use = [
              "mpv"
              "open"
            ];
          }
          # Web
          {
            mime = "{text/html,application/xhtml+xml}";
            use = [
              "firefox"
              "open"
            ];
          }
        ];
      };
    };

    # GTK appearance: adw-gtk3 theme + Papirus-Dark icons. gtk.enable also
    # writes settings.ini; Noctalia's gtk.css templates layer on top and keep
    # working because the template does not touch settings.ini.
    gtk.enable = true;
    gtk.theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3";
    };
    gtk.iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };

    # yazi as the default directory-opener via xdg-terminal-exec, pinned to
    # kitty. dconf prefer-dark feeds xdg-desktop-portal-gtk (kept in dconf,
    # not settings.ini, so Noctalia's GTK templates keep owning that file).
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "yazi.desktop";
      };
    };
    xdg.configFile."xdg-terminals.list".text = ''
      kitty.desktop
    '';

    dconf = {
      enable = true;
      settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        font-name = "Inter 11";
        document-font-name = "Inter 11";
        monospace-font-name = "JetBrainsMono Nerd Font 11";
      };
    };

    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
    };

    # kitty + zoxide are installed by their programs.*.enable above.
    home.packages = with pkgs; [
      xdg-terminal-exec
      wl-clipboard
      brightnessctl
      playerctl
      pavucontrol
      curl

      firefox
      stremio-linux-shell
      proton-vpn
      libreoffice
      zathura
      obs-studio
      imv
      mpv
      netbeans
      localsend

      # OCR (English + Indonesian language data only).
      (tesseract.override {
        enableLanguages = [
          "eng"
          "ind"
        ];
      })
      grim
      slurp

      lutgen

      fastfetch
      btop
      eza
      bat
      lazygit

      # Required by the Noctalia LibreOffice template's apply.sh (assembles
      # the .oxt with `zip -qr` on theme change; yazi's zip is wrapped).
      zip
    ];
  };
}
