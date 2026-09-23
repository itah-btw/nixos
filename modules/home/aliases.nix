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
    nswitch = "sudo nh os switch /etc/nixos";
    ntest = "sudo nh os test /etc/nixos";
    nclean = "sudo nh clean all --keep 5";
    gc14 = "sudo nix-collect-garbage --delete-older-than 14d";
    optimize = "sudo nix-store --optimise";
    gen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
    rollback = "sudo nix-env --rollback --profile /nix/var/nix/profiles/system";
    doctor = "nix doctor";
  };
  pushBash = ''
    push() {
      [ -n "$1" ] || { echo "usage: push <msg>" >&2; return 1; }
      nix fmt /etc/nixos && \
      git -C /etc/nixos add -A && \
      git -C /etc/nixos commit -m "$*" && \
      git -C /etc/nixos push
    }
  '';
in
{
  flake.homeManagerModules.aliases = { ... }: {
    programs.bash = {
      shellAliases = aliases;
      initExtra = pushBash;
    };
    programs.fish = {
      shellAliases = aliases;
    };
    programs.fish.functions.push = {
      description = "Format, stage, commit and push the /etc/nixos flake";
      body = ''
        if test (count $argv) -lt 1
          echo "usage: push <msg>" >&2
          return 1
        end
        set -l msg (string join " " -- $argv)
        nix fmt /etc/nixos; and \
        git -C /etc/nixos add -A; and \
        git -C /etc/nixos commit -m "$msg"; and \
        git -C /etc/nixos push
      '';
    };
  };
}
