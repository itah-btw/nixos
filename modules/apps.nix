# Everyday apps and their dotfiles. Aliases: aliases.nix.
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

    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      shellWrapperName = "y";
      extraPackages = with pkgs; [
        p7zip
        zstd
      ];
      plugins.compress = pkgs.yaziPlugins.compress;
      keymap.mgr.prepend_keymap = [
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
        # yazi matches only the FIRST rule whose mime matches
        # (yazi-config/src/open/open_rules.rs:26), so order is load-bearing:
        # text/html would otherwise be claimed by the text/* rule below and
        # never reach Firefox.
        open.prepend_rules = [
          {
            mime = "{text/html,application/xhtml+xml}";
            use = [
              "firefox"
              "open"
            ];
          }
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
          {
            mime = "application/{msword,vnd.ms-excel,vnd.ms-powerpoint,vnd.openxmlformats-officedocument.wordprocessingml.document,vnd.openxmlformats-officedocument.spreadsheetml.sheet,vnd.openxmlformats-officedocument.presentationml.presentation,vnd.oasis.opendocument.*}";
            use = [
              "libreoffice"
              "open"
            ];
          }
          {
            mime = "image/*";
            use = [
              "imv-dir"
              "open"
            ];
          }
          {
            mime = "{audio,video}/*";
            use = [
              "mpv"
              "open"
            ];
          }
        ];
      };
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

    # yazi as the directory-opener. prefer-dark lives in dconf, not
    # settings.ini, so Noctalia's GTK templates keep owning that file.
    xdg.mimeApps = {
      enable = true;
      defaultApplications."inode/directory" = "yazi.desktop";
    };
    # The stock yazi .desktop sets Terminal=true and runs `yazi %f` with no TTY
    # (ENOTTY, nothing opens). Ours opens in kitty.
    xdg.desktopEntries.yazi = {
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

    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };

    # kitty and zoxide come from their programs.*.enable above.
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

      # OCR: English + Indonesian.
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

      # Telescope live_grep/find_files, plus CLI.
      ripgrep
      fd
      fzf
      # zip/unzip are needed on the session PATH, not only via yazi: the
      # Noctalia LibreOffice template's apply.sh shells out to `zip -qr`.
      unzip
      zip

      # gdbus, for Noctalia's Phone Connect plugin; without it the device list
      # stays empty. zenity is that plugin's share/avatar file picker.
      glib
      zenity

      # Android debugging; the udev uaccess rules are automatic.
      android-tools
      # Android OTA extraction (payload bins from update / factory images).
      payload-dumper-go
    ];
  };
}
