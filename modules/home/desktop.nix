{
  flake.homeManagerModules.desktop =
    {
      config,
      constants,
      lib,
      pkgs,
      ...
    }:
    {
      home.pointerCursor = {
        enable = true;
        package = pkgs.adwaita-icon-theme;
        name = constants.cursorTheme;
        size = constants.cursorSize;
        gtk.enable = true;
      };

      # Sandboxes see neither HM's files store nor host dconf, so symlinked
      # themes dangle and GTK falls back to Adwaita. Repoint the links at the
      # exposed package path, seed each app's dconf, pin the cursor env.
      home.activation.flatpakCursorTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ln -sfn ${pkgs.adwaita-icon-theme}/share/icons/${constants.cursorTheme} ${config.home.homeDirectory}/.icons/${constants.cursorTheme}
        ln -sfn ${pkgs.adwaita-icon-theme}/share/icons/${constants.cursorTheme} ${config.home.homeDirectory}/.local/share/icons/${constants.cursorTheme}
        ${pkgs.flatpak}/bin/flatpak override --user \
          --filesystem=xdg-data/icons:ro \
          '--filesystem=~/.icons:ro' \
          --filesystem=${pkgs.adwaita-icon-theme}:ro \
          --env=XCURSOR_THEME=${constants.cursorTheme} \
          --env=XCURSOR_SIZE=${toString constants.cursorSize}
        for app in $(${pkgs.flatpak}/bin/flatpak list --app --user --columns=application 2>/dev/null || true); do
          ${pkgs.flatpak}/bin/flatpak run --command=gsettings "$app" set org.gnome.desktop.interface cursor-theme '${constants.cursorTheme}' || true
          ${pkgs.flatpak}/bin/flatpak run --command=gsettings "$app" set org.gnome.desktop.interface cursor-size ${toString constants.cursorSize} || true
        done
      '';

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
        EDITOR = "nvim";
        NH_FLAKE = constants.root;
        # Qt6 defaults to the xdgdesktopportal theme, which ignores the
        # configured icon theme; route it through GTK settings instead.
        QT_QPA_PLATFORMTHEME = "gtk3";
        # st renders truecolor but never advertises it, so TUIs that gate on
        # this variable (opencode) would downgrade to 256 colors without it.
        COLORTERM = "truecolor";
      };

      xdg.userDirs = {
        enable = true;
        pictures = "${config.home.homeDirectory}/Pictures";
      };
      home.file."Pictures/Wallpapers/.keep".text = "";

      # st is the only terminal: yazi's desktop entry and xdg-terminal-exec
      # both resolve through here.
      xdg.desktopEntries.st = {
        name = "st";
        comment = "Simple terminal";
        exec = "st";
        icon = "utilities-terminal";
        terminal = false;
        categories = [
          "System"
          "TerminalEmulator"
        ];
      };

      xdg.configFile."xdg-terminals.list".text = ''
        st.desktop
      '';
    };
}
