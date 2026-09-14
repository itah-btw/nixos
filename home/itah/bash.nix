{...}: {
  programs.bash = {
    enable = true;
    # Aliases stage /etc/nixos before building (flakes ignore untracked files; staging != committing).
    shellAliases = {
      update = "sudo nix flake update /etc/nixos";
      check = "sudo nix flake check /etc/nixos";
      fmt = "sudo alejandra /etc/nixos";
      upgrade = "sudo systemctl start nixos-upgrade.service";
      rebuild = "git -C /etc/nixos add -A && sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      rebt = "git -C /etc/nixos add -A && sudo nixos-rebuild test --flake /etc/nixos#nixos";
      boot = "git -C /etc/nixos add -A && sudo nixos-rebuild boot --flake /etc/nixos#nixos";
      drv = "git -C /etc/nixos add -A && sudo nixos-rebuild dry-run --flake /etc/nixos#nixos";
      gc = "sudo nix-collect-garbage --delete-older-than 7d && sudo nix-store --optimise";
      gcr = "sudo nix-collect-garbage -d && sudo nix-store --optimise";
      gens = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      rollback = "sudo nixos-rebuild switch --rollback";
      search = "nix search nixpkgs";
      npush = "nixsync";
      npull = "sudo git -C /etc/nixos pull --rebase";
    };
    bashrcExtra = ''
      # Commit + push /etc/nixos (auto-run after rebuild/update, or `npush`).
      # /etc/nixos is root-owned, so git runs via sudo (root's SSH key auths to GitHub).
      nixsync() {
        local g="/etc/nixos" msg
        msg="sync: $(date '+%F %T')"
        [ -n "$1" ] && msg="$1"
        sudo git -C "$g" add -A || return 1
        if sudo git -C "$g" diff --cached --quiet; then
          echo "nothing to commit"
          return 0
        fi
        sudo git -C "$g" commit -m "$msg" && sudo git -C "$g" push
      }
    '';
    profileExtra = ''
      # No display manager: tty1 autologin -> startx -> oxwm.
      export CM_DIR="$HOME/.cache/clipmenu"
      # oxwm is non-reparenting; Java/Swing apps (e.g. NetBeans) need this.
      export _JAVA_AWT_WM_NONREPARENTING=1
      export XCURSOR_THEME=catppuccin-mocha-mauve-cursors
      export XCURSOR_SIZE=24
      if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
        exec startx
      fi
    '';
  };
}
