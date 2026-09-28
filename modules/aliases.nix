# Shell aliases, plus the `push` and `deploy-tv` helpers as PATH scripts -- they
# used to be duplicated as per-shell function bodies in two languages.
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

        # nh auto-elevates with sudo, so it prompts. The flake is positional and
        # pinned to #hp: bare resolves by hostname, switching the wrong host.
        rb = "nh os switch --accept-flake-config ${root}#hp";
        nsu = "nh os switch --update --accept-flake-config ${root}#hp";
        dry = "nh os build ${root}#hp";
        ntest = "nh os test ${root}#hp";
        gen = "nh os info";
        rollback = "nh os rollback";

        # The only thing that prunes generations: every one is a GC root, so the
        # age timer in nix.nix can never remove one.
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
            # fmt only, not lint, so the commit holds what you wrote plus whitespace.
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
            # Build, copy, ask, then switch: only the switch is disruptive.
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

            # -t for the tty sudo prompt. The wrapper, not sw/bin: Nix never
            # marks a store path setuid.
            sudo=/run/wrappers/bin/sudo
            ssh -t "${target}" "$sudo nix-env -p /nix/var/nix/profiles/system --set $toplevel && $sudo $toplevel/bin/switch-to-configuration switch"
          '';
        })
      ];
    };
}
