# Shell aliases, plus the `push` and `deploy-tv` helpers. Aliases are declared
# once for both shells; the helpers are PATH scripts, which they used to
# duplicate as per-shell function bodies in two languages.
{
  flake.homeManagerModules.aliases =
    { constants, pkgs, ... }:
    let
      inherit (constants) root;
      target = "${constants.username}@${constants.tvAddress}";

      aliases = {
        ls = "eza --icons";
        ll = "eza -l --icons --git";
        la = "eza -la --icons --git";
        cat = "bat";
        lg = "lazygit";
        ff = "fastfetch";

        # `rb` is the sudo path, which nh does not cover.
        rb = "sudo nixos-rebuild switch --flake ${root}#hp --accept-flake-config";
        dry = "nh os build --flake ${root}#hp";
        nsu = "nh os switch --update ${root}";
        ntest = "nh os test ${root}";
        nclean = "nh clean all --keep 5";

        gc14 = "sudo nix-collect-garbage --delete-older-than 14d";
        optimize = "sudo nix-store --optimise";
        gen = "sudo nixos-rebuild list-generations";
        rollback = "sudo nixos-rebuild rollback";
        doctor = "nix doctor";
      };
    in
    {
      programs.bash.shellAliases = aliases;
      programs.fish.shellAliases = aliases;

      home.packages = [
        (pkgs.writeShellApplication {
          name = "push";
          runtimeInputs = [
            pkgs.git
            pkgs.nix
          ];
          text = ''
            if [ "$#" -lt 1 ]; then
              echo "usage: push <msg>" >&2
              exit 1
            fi
            cd ${root}
            # nix fmt only reformats. `nix lint` is deliberately not run here,
            # so this commit holds only what you wrote, plus whitespace.
            nix fmt
            git add -A
            git commit -m "$*"
            git push
          '';
        })

        (pkgs.writeShellApplication {
          name = "deploy-tv";
          runtimeInputs = [
            pkgs.git
            pkgs.nix
            pkgs.openssh
          ];
          text = ''
            # Build here, copy over the LAN, ask, then switch. Only the switch
            # is disruptive, so the ask comes after the copy.
            toplevel=$(nix build --print-out-paths --no-link ${root}#nixosConfigurations.tv.config.system.build.toplevel) || exit 1
            export NIX_SSHOPTS="-o StrictHostKeyChecking=accept-new"
            nix copy --to "ssh://${target}" "$toplevel" || exit 1

            read -r -p "Copied $toplevel. Switch the TV now (interrupts playback)? [y/N] " confirm
            case "$confirm" in
              y | Y) ;;
              *)
                echo "not switching; activate later by re-running deploy-tv"
                exit 0
                ;;
            esac

            # sudo is absolute: an `ssh host cmd` session is a non-login shell
            # and may not have /run/current-system/sw/bin on PATH. `ssh -t`
            # gives it a tty, so sudo prompts for the password there and it is
            # never stored here. sudo's credential cache means one prompt
            # covers both commands.
            sudo=/run/current-system/sw/bin/sudo
            ssh -t "${target}" "$sudo nix-env -p /nix/var/nix/profiles/system --set $toplevel && $sudo $toplevel/bin/switch-to-configuration switch"
          '';
        })
      ];
    };
}
