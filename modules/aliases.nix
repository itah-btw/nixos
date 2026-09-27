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

        # Every rebuild/GC path goes through nh, which auto-elevates with sudo
        # and so prompts for the password. The flake is positional (nh has no
        # --flake) and pinned to #hp: a bare flake resolves by hostname, which
        # would switch whichever host you happen to be logged into.
        rb = "nh os switch --accept-flake-config ${root}#hp";
        nsu = "nh os switch --update --accept-flake-config ${root}#hp";
        dry = "nh os build ${root}#hp";
        ntest = "nh os test ${root}#hp";
        gen = "nh os info";
        rollback = "nh os rollback";

        # The only thing that prunes system generations: every generation is a GC
        # root, so the age-based timer in nix.nix can never remove one. Keeps 5,
        # so boot.loader.systemd-boot.configurationLimit is a non-binding
        # ceiling above it.
        nclean = "nh clean all --keep 5";

        # No nh equivalent for these two; they are plain nix commands.
        optimize = "sudo nix-store --optimise";
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
            # nix fmt only reformats. `nix run .#lint` is deliberately not run
            # here, so this commit holds only what you wrote, plus whitespace.
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

            # `ssh -t` for the tty sudo needs to prompt on. The wrapper, not
            # sw/bin: Nix never marks a store path setuid, so that one fails.
            sudo=/run/wrappers/bin/sudo
            ssh -t "${target}" "$sudo nix-env -p /nix/var/nix/profiles/system --set $toplevel && $sudo $toplevel/bin/switch-to-configuration switch"
          '';
        })
      ];
    };
}
