{
  flake.homeManagerModules.yazi = { pkgs, ... }: {
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

    xdg.mimeApps = {
      enable = true;
      defaultApplications."inode/directory" = "yazi.desktop";
    };

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
      ];
    };

  };
}
