# Single source of truth for bash + fish aliases and the `push` / `deploy-tv` helpers.
_:
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
    nswitch = "nh os switch /etc/nixos";
    nsu = "nh os switch --update /etc/nixos";
    ntest = "nh os test /etc/nixos";
    nclean = "nh clean all --keep 5";
    gc14 = "sudo nix-collect-garbage --delete-older-than 14d";
    optimize = "sudo nix-store --optimise";
    gen = "sudo nixos-rebuild list-generations";
    rollback = "sudo nixos-rebuild rollback";
    doctor = "nix doctor";
  };
  pushBash = ''
    push() {
      [ -n "$1" ] || { echo "usage: push <msg>" >&2; return 1; }
      ( cd /etc/nixos && nix fmt && \
        git add -A && \
        git commit -m "$*" && \
        git push )
    }
  '';
  # Remote deploy for the tv box: build the closure here, copy it over LAN,
  # then activate remotely. Only the last step is disruptive, so confirmation
  # happens after the copy. Plain ssh -- the box authorises this machine's key
  # (modules/tv/openssh.nix), and sudo on the box still wants its password.
  deployTvBash = ''
    deploy-tv() {
      local toplevel st confirm
      toplevel=$(nix build --print-out-paths --no-link /etc/nixos#nixosConfigurations.tv.config.system.build.toplevel) || return 1
      NIX_SSHOPTS="-o StrictHostKeyChecking=accept-new" nix copy --to "ssh://itah@192.168.0.62" "$toplevel" || return 1
      read -p "Copied $toplevel. Switch the TV now (interrupts playback)? [y/N] " confirm
      [ "$confirm" = "y" ] || [ "$confirm" = "Y" ] || { echo "not switching; activate later by re-running deploy-tv"; return 0; }
      ssh -o StrictHostKeyChecking=accept-new "itah@192.168.0.62" "echo 1909 | sudo -S nix-env -p /nix/var/nix/profiles/system --set $toplevel && echo 1909 | sudo -S $toplevel/bin/switch-to-configuration switch"
      st=$?
      return $st
    }
  '';
in
{
  flake.homeManagerModules.aliases = _: {
    programs.bash = {
      shellAliases = aliases;
      initExtra = pushBash + deployTvBash;
    };
    programs.fish = {
      shellAliases = aliases;
    };
    programs.fish.functions."deploy-tv" = {
      description = "Build the tv closure here, copy it to the box, ask, then switch";
      body = ''
        set -l toplevel (nix build --print-out-paths --no-link /etc/nixos#nixosConfigurations.tv.config.system.build.toplevel); or return 1
        env "NIX_SSHOPTS=-o StrictHostKeyChecking=accept-new" nix copy --to "ssh://itah@192.168.0.62" $toplevel; or return 1
        read -P "Copied $toplevel. Switch the TV now (interrupts playback)? [y/N] " confirm
        if test "$confirm" != y; and test "$confirm" != Y
          echo "not switching; activate later by re-running deploy-tv"
          return 0
        end
        ssh -o StrictHostKeyChecking=accept-new "itah@192.168.0.62" "echo 1909 | sudo -S nix-env -p /nix/var/nix/profiles/system --set $toplevel && echo 1909 | sudo -S $toplevel/bin/switch-to-configuration switch"
        return $status
      '';
    };
    programs.fish.functions.push = {
      description = "Format, stage, commit and push the /etc/nixos flake";
      body = ''
        if test (count $argv) -lt 1
          echo "usage: push <msg>" >&2
          return 1
        end
        set -l msg (string join " " -- $argv)
        set -l cwd $PWD
        cd /etc/nixos || return 1
        nix fmt; and \
        git add -A; and \
        git commit -m "$msg"; and \
        git push
        set -l st $status
        cd $cwd
        return $st
      '';
    };
  };
}
