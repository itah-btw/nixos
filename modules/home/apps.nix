# Everyday apps + their dotfiles.
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
        # Experimental cursor trail; odd number, higher = longer trail.
        cursor_trail = 3;
        # Glass terminal: translucent background + compositor blur behind it.
        # Umbriel window rule blurs all windows (see umbriel.nix), so the
        # transparent backdrop shows a frosted wallpaper. Made lighter (more
        # transparent) than the Noctalia shell surfaces.
        background_opacity = 0.85;
        background_blur = 30;
      };
      # Wiring so the Noctalia->Kitty template output is actually loaded.
      # Noctalia writes themes/noctalia.conf at runtime; this include is the
      # declarative half. apply.sh cannot add it itself because kitty.conf
      # is a read-only store symlink. Palette values stay in the theme file,
      # not here.
      extraConfig = ''
        include themes/noctalia.conf
      '';
    };

    # Shell aliases for the TUI apps installed above.
    programs.bash = {
      enable = true;
      shellAliases = {
        # eza (ls replacement)
        ls = "eza --icons";
        ll = "eza -l --icons --git";
        la = "eza -la --icons --git";
        l = "eza --icons";
        # bat (cat replacement)
        cat = "bat";
        # lazygit
        lg = "lazygit";
        # fastfetch
        ff = "fastfetch";
        # --- NixOS maintenance --------------------------------------------
        rb = "sudo nixos-rebuild switch --flake /etc/nixos#hp --accept-flake-config";
        dry = "nixos-rebuild dry-build --flake /etc/nixos#hp --accept-flake-config";
        update = "nix flake update --flake /etc/nixos";
        gc = "sudo nix-collect-garbage --delete-old";
        gc14 = "sudo nix-collect-garbage --delete-older-than 14d";
        optimize = "sudo nix-store --optimise";
        gen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
        rollback = "sudo nix-env --rollback --profile /nix/var/nix/profiles/system";
        doctor = "nix doctor";
      };
    };

    # Yazi file manager (dotfile: ~/.config/yazi/)
    #   - compress: yaziPlugins.compress (c a a / c a p), needs zip/7z in PATH
    #   - extract:  builtin "Extract here" on Enter + c x (uses 7zz/7z)
    programs.yazi = {
      enable = true;
      # `y` function = open yazi, cd into last dir on exit.
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
            on = [ "c" "a" "a" ];
            run = "plugin compress";
            desc = "Archive selected files";
          }
          {
            on = [ "c" "a" "p" ];
            run = "plugin compress -p";
            desc = "Archive selected files (password)";
          }
          {
            on = [ "c" "x" ];
            run = "shell -- ya pub extract --list %s";
            desc = "Extract selected archives here";
          }
        ];
      };
      settings = {
        # Openers for the apps installed on this machine. Types without a
        # dedicated opener fall through to the default "open" (xdg-open).
        opener = {
          zathura = [
            {
              run = "zathura %s";
              desc = "Open with Zathura";
              for = "linux";
              orphan = true;
            }
          ];
          imv = [
            {
              run = "imv %s";
              desc = "Open with imv";
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
              run = "firefox %s1";
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
            use = [ "nvim" "edit" ];
          }
          {
            mime = "application/{json,ndjson,javascript,wine-extension-ini}";
            use = [ "nvim" "edit" ];
          }
          # Documents
          {
            mime = "application/{pdf,djvu}";
            use = [ "zathura" "open" ];
          }
          {
          mime = "{application/epub+zip,application/vnd.comicbook+zip}";
          use = [ "zathura" "open" ];
          }
          # Office
          {
            mime = "application/{msword,vnd.ms-excel,vnd.ms-powerpoint,vnd.openxmlformats-officedocument.wordprocessingml.document,vnd.openxmlformats-officedocument.spreadsheetml.sheet,vnd.openxmlformats-officedocument.presentationml.presentation,vnd.oasis.opendocument.*}";
            use = [ "libreoffice" "open" ];
          }
          # Images
          {
            mime = "image/*";
            use = [ "imv" "open" ];
          }
          # Media
          {
            mime = "{audio,video}/*";
            use = [ "mpv" "open" ];
          }
          # Web
          {
            mime = "{text/html,application/xhtml+xml}";
            use = [ "firefox" "open" ];
          }
        ];
      };
    };

    # Papirus-Dark icon theme (folders/icons used by GTK apps + file managers).
    # NOTE: gtk.enable must be true — without it HM ignores iconTheme entirely
    # (no settings.ini written, package not installed). HM does not manage
    # gtk.css unless extraCss is set, so Noctalia's gtk3/gtk4 templates
    # (noctalia.css @import) keep working untouched.
    gtk.enable = true;
    # adw-gtk3: libadwaita-style GTK3 theme that follows the
    # org.gnome.desktop.interface color-scheme (prefer-dark set below),
    # unlike stock Adwaita. Noctalia's gtk.css/noctalia.css accents
    # layer on top; the template doesn't touch settings.ini, so no conflict.
    gtk.theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3";
    };
    gtk.iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };

    # Yazi as the default file manager for directories.
    # yazi.desktop ships Terminal=true, so gio/xdg-open launches it through
    # xdg-terminal-exec, pinned to kitty below.
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "yazi.desktop";
      };
    };
    xdg.configFile."xdg-terminals.list".text = ''
      kitty.desktop
    '';

    # Prefer-dark for xdg-desktop-portal-gtk (Firefox save/open dialogs),
    # which reads org.gnome.desktop.interface color-scheme. Kept in dconf
    # (not settings.ini) so Noctalia's GTK templates keep owning that file.
    dconf = {
      enable = true;
      settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    };

    # zoxide: fast `z` directory jumping (bash init provides the `z` function).
    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
    };

    home.packages = with pkgs; [
      kitty
      # Needed so gio/xdg-open can launch Terminal=true .desktop apps (yazi).
      xdg-terminal-exec
      wl-clipboard
      brightnessctl
      playerctl
      pavucontrol
      fprintd
      curl

      # --- Daily essentials -------------------------------------------------
      firefox
      proton-vpn
      libreoffice
      zathura
      obs-studio
      imv
      mpv
      netbeans
      localsend

      # Firmware update CLI (daemon enabled in desktop/session.nix).
      fwupd

      # OCR (English + Indonesian language data; only these are bundled).
      (tesseract.override { enableLanguages = [ "eng" "ind" ]; })
      grim
      slurp

      # --- TUI / terminal helpers -----------------------------------------
      fastfetch
      btop
      eza
      bat
      lazygit
      zoxide

      # Required by the Noctalia LibreOffice template's apply.sh: it assembles
      # the Noctalia ColorScheme .oxt with `zip -qr` on every theme change.
      # (yazi's extraPackages also contain zip, but those are wrapped for yazi
      # only, not on user PATH.)
      zip
    ];
  };
}
