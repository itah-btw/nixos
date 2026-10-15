{
  flake.homeManagerModules.scripts =
    { constants, pkgs, ... }:
    let
      inherit (constants) root generationKeep;

      # Warns once per discharge cycle at 15% or below; the flag lives in the
      # runtime dir so a reboot clears it. No battery sysfs, exits quietly.
      batteryWatch = pkgs.writeShellApplication {
        name = "battery-watch";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.libnotify
        ];
        text = ''
          flag="''${XDG_RUNTIME_DIR:-/tmp}/battery-low-notified"
          sysfs="''${BATTERY_SYSFS:-/sys/class/power_supply}"
          cap=""
          status=""
          for d in "$sysfs"/BAT*; do
            [ -r "$d/capacity" ] || continue
            [ -r "$d/status" ] || continue
            cap=$(cat "$d/capacity")
            status=$(cat "$d/status")
            break
          done
          [ -n "$cap" ] || exit 0
          [ -n "$status" ] || exit 0
          if [ "$status" = "Discharging" ] && [ "$cap" -le 15 ]; then
            if [ ! -f "$flag" ]; then
              # Never fail an unattended timer run over a missed popup.
              notify-send -u critical "Battery low" "''${cap}% remaining, plug in" || true
              touch "$flag"
            fi
          else
            rm -f "$flag"
          fi
        '';
      };
      aliases = {
        ls = "eza --icons";
        ll = "eza -l --icons --git";
        la = "eza -la --icons --git";
        cat = "bat";

        rb = "nh os switch --accept-flake-config ${root}#hp";
        nsu = "nh os switch --update --accept-flake-config ${root}#hp";
        dry = "nh os build --accept-flake-config ${root}#hp";
        ntest = "nh os test --accept-flake-config ${root}#hp";
        nboot = "nh os boot --accept-flake-config ${root}#hp";
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

      systemd.user.services.battery-watch = {
        Unit.Description = "Low-battery desktop notification";
        Service = {
          Type = "oneshot";
          ExecStart = "${batteryWatch}/bin/battery-watch";
        };
      };

      systemd.user.timers.battery-watch = {
        Unit.Description = "Check battery level every few minutes";
        Timer = {
          OnBootSec = "2min";
          OnUnitActiveSec = "2min";
        };
        Install.WantedBy = [ "timers.target" ];
      };

      home.packages = [
        (pkgs.writeShellApplication {
          name = "ocr-copy";
          # The wrapper sees only runtimeInputs on PATH, so tools used here
          # must be listed even when home.packages already ships them.
          # X11 build: region select via slop-driven maim, out via xclip.
          runtimeInputs = [
            pkgs.maim
            pkgs.slop
            pkgs.xclip
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
            maim -s "$tmp" || exit 1
            text=$(tesseract "$tmp" - -l eng+ind 2>/dev/null) || {
              echo "ocr-copy: tesseract failed; clipboard untouched" >&2
              exit 1
            }
            if [ -z "$text" ]; then
              echo "ocr-copy: no text recognised; clipboard untouched" >&2
              exit 1
            fi
            printf '%s' "$text" | xclip -selection clipboard
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
            # Shellcheck only runs when helpers are built as part of a toplevel.
            nix build --no-link ${root}#nixosConfigurations.hp.config.system.build.toplevel > /dev/null
            git add -A
            git commit -m "$*"
            git push
          '';
        })
      ];
    };
}
