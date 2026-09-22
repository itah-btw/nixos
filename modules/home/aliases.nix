# Single source of truth for bash + fish aliases and the `push` helper.
{ ... }:
let
  aliases = {
    ls = "eza --icons";
    ll = "eza -l --icons --git";
    la = "eza -la --icons --git";
    l = "eza --icons";
    cat = "bat";
    lg = "lazygit";
    ff = "fastfetch";
    rb = "sudo nixos-rebuild switch --flake /etc/nixos#hp --accept-flake-config";
    dry = "nixos-rebuild dry-build --flake /etc/nixos#hp --accept-flake-config";
    update = "nix flake update --flake /etc/nixos";
    gc14 = "sudo nix-collect-garbage --delete-older-than 14d";
    optimize = "sudo nix-store --optimise";
    gen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
    rollback = "sudo nix-env --rollback --profile /nix/var/nix/profiles/system";
    doctor = "nix doctor";
  };
  pushBash = ''
    push() {
      [ -n "$1" ] || { echo "usage: push <msg>" >&2; return 1; }
      git -C /etc/nixos add -A && \
      git -C /etc/nixos commit -m "$1" && \
      git -C /etc/nixos push
    }
  '';
in
{
  flake.homeManagerModules.aliases = { ... }: {
    programs.bash = {
      enable = true;
      shellAliases = aliases;
      initExtra = pushBash;
    };
    programs.fish = {
      enable = true;
      shellAliases = aliases;
    };
    programs.fish.functions.push = {
      description = "Stage, commit and push the /etc/nixos flake";
      body = ''
        if test (count $argv) -lt 1
          echo "usage: push <msg>" >&2
          return 1
        end
        git -C /etc/nixos add -A; and \
        git -C /etc/nixos commit -m "$argv[1]"; and \
        git -C /etc/nixos push
      '';
    };
  };
}
