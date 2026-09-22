# Fish shell + Starship prompt.
#
# System side enables fish globally (registers /etc/shells, completions)
# and makes it itah's login shell. Home side manages fish + starship
# dotfiles. Shell aliases are shared with bash (see apps.nix) so `rb`,
# `dry`, `ls`, etc. work identically in both shells.
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
      # No greeting: an (empty) fish_greeting suppresses fish's default
      # "Welcome to fish..." message on interactive startup.
      interactiveShellInit = ''
        set -g fish_greeting
      '';
      shellAliases = {
        # eza (ls replacement)
        ls = "eza --icons";
        ll = "eza -l --icons --git";
        la = "eza -la --icons --git";
        l = "eza --icons";
        # bat (cat replacement)
        cat = "bat";
        # lazygit
        lg = "lazygit";
        # fastfetch
        ff = "fastfetch";
        # --- NixOS maintenance --------------------------------------------
        rb = "sudo nixos-rebuild switch --flake /etc/nixos#hp --accept-flake-config";
        dry = "nixos-rebuild dry-build --flake /etc/nixos#hp --accept-flake-config";
        update = "nix flake update --flake /etc/nixos";
        gc = "sudo nix-collect-garbage --delete-old";
        gc14 = "sudo nix-collect-garbage --delete-older-than 14d";
        optimize = "sudo nix-store --optimise";
        gen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
        rollback = "sudo nix-env --rollback --profile /nix/var/nix/profiles/system";
        doctor = "nix doctor";
      };
    };

    # `push <msg>` — stage + commit + push the NixOS config in one shot.
    programs.fish.functions.push = {
      description = "Stage, commit and push the /etc/nixos flake";
      body = ''
        git -C /etc/nixos add -A; and \
        git -C /etc/nixos commit -m "$argv[1]"; and \
        git -C /etc/nixos push
      '';
    };

    # Starship: integration only (prompt init in fish/bash). The config file
    # (~/.config/starship.toml) is runtime-managed by Noctalia's Starship
    # template (palette sync via marker injection), so settings/presets stay
    # empty here on purpose — any HM-managed content would clobber Noctalia's
    # file on switch AND become a read-only store symlink that Noctalia's
    # apply.sh cannot update (see noctalia issue #3101). Same reasoning as
    # the Noctalia theming exception in noctalia.nix. The prompt uses stock
    # layout with `palette = "noctalia"` plus a manual `[character]` tweak
    # (moai leading into ❯) outside Noctalia's markers, so it adopts
    # the live Noctalia theme and survives theme switches; enforced by the
    # hp-starship-unmanaged guard in checks.nix.
    # Terminal needs a Nerd Font for prompt glyphs; JetBrainsMono Nerd Font
    # is installed system-wide in desktop/session.nix and set as kitty's
    # font in apps.nix.
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };

    # Fish integrations for tools already configured for bash in apps.nix.
    programs.zoxide.enableFishIntegration = true;
    programs.yazi.enableFishIntegration = true;
  };
}
