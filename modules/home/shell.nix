{
  flake.homeManagerModules.shell = {
    programs.bash.enable = true;
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting
      '';
      # Console login on tty1 execs straight into X (getty autologin is set
      # in nixos/session.nix). Other ttys keep a plain shell.
      loginShellInit = ''
        if test -z "$DISPLAY"; and [ (tty) = /dev/tty1 ]
          exec startx
        end
      '';
    };

    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };

    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      nix-direnv.enable = true;
    };

    programs.zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };
  };
}
