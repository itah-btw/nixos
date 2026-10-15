{
  flake.homeManagerModules.shell = {
    programs.bash.enable = true;
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting
      '';
      # Console login on tty1 starts X (getty autologin is set in
      # nixos/session.nix). No exec: a failed startx — or logging out of
      # the WM — lands in a console shell instead of a respawn loop.
      loginShellInit = ''
        if test -z "$DISPLAY"; and [ (tty) = /dev/tty1 ]
          startx; or echo "startx failed; staying in console" >&2
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
