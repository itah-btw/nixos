{
  flake.homeManagerModules.shell = {
    programs.bash = {
      enable = true;
      initExtra = ''
        if [ -z "''${FASTFETCH_GREETING:-}" ]; then
          export FASTFETCH_GREETING=1
          fastfetch
        fi
      '';
    };
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting
        if not set -q FASTFETCH_GREETING
          set -gx FASTFETCH_GREETING 1
          fastfetch
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
