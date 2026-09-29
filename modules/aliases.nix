{
  flake.homeManagerModules.aliases =
    { constants, pkgs, ... }:
    let
      inherit (constants) root generationKeep;
      target = "${constants.username}@${constants.tvAddress}";

      aliases = {
        ls = "eza --icons";
        ll = "eza -l --icons --git";
        la = "eza -la --icons --git";
        cat = "bat";

        rb = "nh os switch --accept-flake-config ${root}#hp";
        nsu = "nh os switch --update --accept-flake-config ${root}#hp";
        dry = "nh os build ${root}#hp";
        ntest = "nh os test ${root}#hp";
        rollback = "nh os rollback";

        # age timer in nix.nix can never remove one. Keep matches boot's limit.
        nclean = "nh clean all --keep ${toString generationKeep}";

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
            [ "$#" -ge 1 ] || { echo "usage: push <msg>" >&2; exit 1; }
            cd ${root} && nix fmt && git add -A && git commit -m "$*" && git push
          '';
        })

        (pkgs.writeShellApplication {
          name = "deploy-tv";
          runtimeInputs = [
            pkgs.nix
            pkgs.openssh
          ];
          text = ''
            toplevel=$(nix build --print-out-paths --no-link ${root}#nixosConfigurations.tv.config.system.build.toplevel) || exit 1
            nix copy --to "ssh://${target}" "$toplevel" || exit 1
            read -r -p "Switch the TV now (interrupts playback)? [y/N] " c
            case "$c" in y | Y) ;; *) echo "copied; re-run deploy-tv to switch"; exit 0 ;; esac
            # Nix never marks a store path setuid, so the wrapper (not sw/bin).
            s=/run/wrappers/bin/sudo
            ssh -t "${target}" "$s nix-env -p /nix/var/nix/profiles/system --set $toplevel && $s $toplevel/bin/switch-to-configuration switch"
          '';
        })
      ];
    };
}
