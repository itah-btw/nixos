# Single source of truth for bash + fish aliases and the `push` / `deploy-tv` helpers.
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
    nswitch = "nh os switch /etc/nixos";
    nsu = "nh os switch --update /etc/nixos";
    ntest = "nh os test /etc/nixos";
    nclean = "nh clean all --keep 5";
    gc14 = "sudo nix-collect-garbage --delete-older-than 14d";
    optimize = "sudo nix-store --optimise";
    gen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
    rollback = "sudo nix-env --rollback --profile /nix/var/nix/profiles/system";
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
  # Remote deploy for the tv box (password-only ssh, see tv skill): build the
  # closure here, copy it over LAN, then activate remotely. Only the last
  # step is disruptive, so confirmation happens after the copy.
  deployTvBash = ''
    deploy-tv() {
      local wrap toplevel st confirm tv_env
      wrap=$(mktemp -d) || return 1
      printf '#!/bin/sh\nexec sshpass -e ssh "$@"\n' > "$wrap/ssh" && chmod +x "$wrap/ssh" || { rm -rf "$wrap"; return 1; }
      tv_env="PATH=$wrap:/nix/store/6w31qyqsggbzdgldvmdsbhhdp1p2ykk1-sshpass-1.10/bin:/run/current-system/sw/bin:/usr/bin:/bin SSHPASS=1909 TERM=xterm"
      toplevel=$(env $tv_env nix build --print-out-paths --no-link /etc/nixos#nixosConfigurations.tv.config.system.build.toplevel) || { rm -rf "$wrap"; return 1; }
      env $tv_env NIX_SSHOPTS="-o StrictHostKeyChecking=accept-new" nix copy --to "ssh://itah@192.168.0.62" "$toplevel" || { rm -rf "$wrap"; return 1; }
      read -p "Copied $toplevel. Switch the TV now (interrupts playback)? [y/N] " confirm
      [ "$confirm" = "y" ] || [ "$confirm" = "Y" ] || { echo "not switching; activate later by re-running deploy-tv"; rm -rf "$wrap"; return 0; }
      env $tv_env sshpass -e ssh -o StrictHostKeyChecking=accept-new "itah@192.168.0.62" "echo 1909 | sudo -S nix-env -p /nix/var/nix/profiles/system --set $toplevel && echo 1909 | sudo -S $toplevel/bin/switch-to-configuration switch"
      st=$?
      rm -rf "$wrap"
      return $st
    }
  '';
in
{
  flake.homeManagerModules.aliases = { ... }: {
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
        set -l wrap (mktemp -d); or return 1
        printf '#!/bin/sh\nexec sshpass -e ssh "$@"\n' > $wrap/ssh; and chmod +x $wrap/ssh; or begin rm -rf $wrap; return 1; end
        set -l tv_env "PATH=$wrap:/nix/store/6w31qyqsggbzdgldvmdsbhhdp1p2ykk1-sshpass-1.10/bin:/run/current-system/sw/bin:/usr/bin:/bin" "SSHPASS=1909" "TERM=xterm"
        set -l toplevel (env $tv_env nix build --print-out-paths --no-link /etc/nixos#nixosConfigurations.tv.config.system.build.toplevel); or begin rm -rf $wrap; return 1; end
        env $tv_env "NIX_SSHOPTS=-o StrictHostKeyChecking=accept-new" nix copy --to "ssh://itah@192.168.0.62" $toplevel; or begin rm -rf $wrap; return 1; end
        read -P "Copied $toplevel. Switch the TV now (interrupts playback)? [y/N] " confirm
        if test "$confirm" != y; and test "$confirm" != Y
          echo "not switching; activate later by re-running deploy-tv"
          rm -rf $wrap
          return 0
        end
        env $tv_env sshpass -e ssh -o StrictHostKeyChecking=accept-new "itah@192.168.0.62" "echo 1909 | sudo -S nix-env -p /nix/var/nix/profiles/system --set $toplevel && echo 1909 | sudo -S $toplevel/bin/switch-to-configuration switch"
        set -l st $status
        rm -rf $wrap
        return $st
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
