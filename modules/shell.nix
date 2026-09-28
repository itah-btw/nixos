# Fish login shell + Starship + direnv. Aliases: aliases.nix.
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

    # Integration only. starship.toml is Noctalia's (palette sync); HM content
    # would make it a read-only symlink (noctalia #3101). starship-unmanaged.
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
  };
}
