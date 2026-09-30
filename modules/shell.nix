{
  flake.nixosModules.shell = { constants, pkgs, ... }: {
    programs.fish.enable = true;
    users.users.${constants.username}.shell = pkgs.fish;
  };

  flake.homeManagerModules.shell = {
    programs.bash.enable = true;
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting
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
