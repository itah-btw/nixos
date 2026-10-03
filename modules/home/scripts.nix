{
  flake.homeManagerModules.scripts =
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
        dry = "nh os build --accept-flake-config ${root}#hp";
        ntest = "nh os test --accept-flake-config ${root}#hp";
        rollback = "nh os rollback";

        # age timer in nixos/system.nix can never remove one. Keep matches boot's limit.
        nclean = "nh clean all --keep ${toString generationKeep}";

        # mariadb.nix clears wantedBy, so it never starts on its own.
        mdb-up = "sudo systemctl start mysql";
        mdb-down = "sudo systemctl stop mysql";

        optimize = "sudo nix-store --optimise";
        doctor = "nix config check";
      };
    in
    {
      programs.bash.shellAliases = aliases;
      programs.fish.shellAliases = aliases;

      home.packages = [
        (pkgs.writeShellApplication {
          name = "brightness-step";
          runtimeInputs = [ pkgs.noctalia ];
          text = ''
            pct=""
            for dev in /sys/class/backlight/*; do
              if [ -r "$dev/brightness" ] && [ -r "$dev/max_brightness" ]; then
                read -r cur < "$dev/brightness"
                read -r max < "$dev/max_brightness"
                # Integer percent; max is never 0 on a real backlight.
                if [ "$max" -gt 0 ] 2>/dev/null; then
                  pct=$(( 100 * cur / max ))
                  break
                fi
              fi
            done
            if [ "$1" = "up" ]; then
              [ -n "$pct" ] || exec noctalia msg brightness-up
              if [ "$pct" -lt 5 ]; then target=$(( pct + 1 )); else target=$(( pct + 5 )); fi
            else
              [ -n "$pct" ] || exec noctalia msg brightness-down
              if [ "$pct" -le 5 ]; then target=$(( pct - 1 )); else target=$(( pct - 5 )); fi
              [ "$target" -lt 1 ] && target=1
            fi
            noctalia msg brightness-set "$target"
          '';
        })
        (pkgs.writeShellApplication {
          name = "ocr-copy";
          runtimeInputs = [
            pkgs.grim
            pkgs.slurp
            pkgs.wl-clipboard
            (pkgs.tesseract.override {
              enableLanguages = [
                "eng"
                "ind"
              ];
            })
          ];
          text = ''
            tmp=$(mktemp --suffix .png)
            trap 'rm -f "$tmp"' EXIT
            grim -g "$(slurp)" "$tmp" || exit 1
            text=$(tesseract "$tmp" - -l eng+ind 2>/dev/null) || {
              echo "ocr-copy: tesseract failed; clipboard untouched" >&2
              exit 1
            }
            if [ -z "$text" ]; then
              echo "ocr-copy: no text recognised; clipboard untouched" >&2
              exit 1
            fi
            printf '%s' "$text" | wl-copy
          '';
        })

        (pkgs.writeShellApplication {
          name = "push";
          runtimeInputs = [
            pkgs.git
            pkgs.nix
          ];
          text = ''
            set -euo pipefail
            [ "$#" -ge 1 ] || { echo "usage: push <msg>" >&2; exit 1; }
            cd ${root}
            # Gate before `git add`, so a red policy cannot leave a commit behind.
            nix fmt
            nix run .#lint
            nix build .#checks.x86_64-linux.policy --no-link
            git add -A
            git commit -m "$*"
            git push
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
