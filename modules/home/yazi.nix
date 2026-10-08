{
  flake.homeManagerModules.yazi = { config, pkgs, ... }: {
    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      shellWrapperName = "y";
      extraPackages = with pkgs; [
        p7zip
        zstd
        imagemagick
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
          librewolf = [
            {
              run = "librewolf %s";
              desc = "Open in LibreWolf";
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
          vis = [
            {
              run = "vis %s";
              desc = "Open in vis";
              for = "linux";
              block = true;
            }
          ];
        };
        open.prepend_rules = [
          {
            mime = "{text/html,application/xhtml+xml}";
            use = [
              "librewolf"
              "open"
            ];
          }
          {
            mime = "text/*";
            use = [
              "vis"
              "edit"
            ];
          }
          {
            mime = "application/{json,ndjson,javascript,wine-extension-ini}";
            use = [
              "vis"
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
      exec = "foot --app-id=yazi yazi %f";
      icon = "yazi";
      terminal = false;
      mimeType = [ "inode/directory" ];
      categories = [
        "System"
        "FileManager"
        "FileTools"
      ];
    };

    home.file.".local/share/icons/hicolor/512x512/apps/yazi.png".source =
      "${config.programs.yazi.package}/share/pixmaps/yazi.png";

  };
}
