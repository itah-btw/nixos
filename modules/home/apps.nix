# Everyday apps + their dotfiles. Shell aliases live in ./aliases.nix.
_: {
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
        # Opacity lives in Umbriel's window rules (umbriel.nix): focused 0.9,
        # unfocused 0.8, and the blur comes from the compositor too. Kitty's
        # own background stays opaque so those rule values are the effective
        # alpha instead of being multiplied twice.
        background_opacity = 1.0;
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
      enableFishIntegration = true;
      shellWrapperName = "y";
      extraPackages = with pkgs; [
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
    # Override the raw yazi package .desktop (Terminal=true, Exec=yazi %f —
    # spawned with no TTY it dies with ENOTTY and nothing opens). Ours opens
    # in kitty so xdg-open actually lands in a terminal file browser.
    xdg.desktopEntries."yazi" = {
      name = "Yazi File Manager";
      comment = "Open directory in the yazi terminal file manager";
      exec = "kitty --class yazi -e yazi %f";
      terminal = false;
      mimeType = [ "inode/directory" ];
      categories = [
        "System"
        "FileManager"
        "FileTools"
        "ConsoleOnly"
      ];
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

    # Shell integrations live with the program they belong to; shell.nix keeps
    # only the shells themselves.
    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };

    # kitty + zoxide are installed by their programs.*.enable above.
    home.packages = with pkgs; [
      xdg-terminal-exec
      wl-clipboard
      brightnessctl
      playerctl
      pavucontrol
      curl
      llama-cpp
      firefox
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

      # Telescope live_grep/find_files + general CLI.
      ripgrep
      fd
      fzf
      # Archives: zip/unzip are here rather than only in yazi's extraPackages
      # because the Noctalia LibreOffice template's apply.sh shells out to
      # `zip -qr` (yazi's copies are wrapped and not on the session PATH).
      unzip
      zip

      # gdbus (glib) — the Noctalia Phone Connect plugin talks to KDE Connect
      # via `gdbus`; without it the device list stays empty ("no devices").
      glib
      # File picker for the plugin's share/avatar ops (kdialog/zenity).
      zenity

      # Android debugging (adb/fastboot; udev uaccess rules are automatic
      # via systemd, no extra NixOS option needed on unstable).
      android-tools
      # Android OTA extraction (payload bins from update images/factory ROMs).
      payload-dumper-go
    ];
  };
}
