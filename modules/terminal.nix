# yazi and umbriel spawn `kitty` by name, so the terminal is load-bearing.
{
  flake.homeManagerModules.terminal = { constants, ... }: {
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

    xdg.configFile."xdg-terminals.list".text = ''
      kitty.desktop
    '';
  };
}
