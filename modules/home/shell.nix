# Fish login shell (system side) + Starship prompt (home side).
# Aliases and `push` live in ./aliases.nix (shared with bash).
{ ... }:
{
  flake.nixosModules.shell =
    { pkgs, ... }:
    {
      programs.fish.enable = true;
      users.users."itah".shell = pkgs.fish;
    };

  flake.homeManagerModules.shell = { ... }: {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting
      '';
    };

    # Integration only. starship.toml is runtime-managed by Noctalia's
    # Starship template (palette sync), so settings/presets stay empty —
    # HM content would clobber Noctalia's file with a read-only symlink
    # (see noctalia issue #3101); enforced by hp-starship-unmanaged.
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };

    programs.zoxide.enableFishIntegration = true;
    programs.yazi.enableFishIntegration = true;
  };
}
