# TV display-mode guard: re-assert 1920x1080@60 (user service + timer).
# Ported verbatim from the box's configuration.nix.
{ ... }:
{
  flake.nixosModules.tv-display =
    { pkgs, ... }:
    {
      # The TV must stay on 1920x1080@60. The EDID marks 1280x720@50 as the
      # *preferred* mode, so a kernel update that shifts the advertised mode
      # list can silently drop the panel to 720p50 with nothing on screen to
      # say so. boot.kernelPackages is linuxPackages_latest, so a new
      # mainline kernel arrives on every update. This re-asserts the mode.
      #
      # Deliberately a no-op when the mode is already correct or the TV is
      # off, and it never manages kwinoutputconfig.json -- KWin owns that.
      systemd.user.services.tv-display-mode-guard =
        let
          script = pkgs.writeShellApplication {
            name = "tv-display-mode-guard";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.jq
              # kscreen-doctor ships in libkscreen, NOT in kscreen. Using
              # kdePackages.kscreen puts no kscreen-doctor on PATH, and the guard
              # then fails open while still logging success.
              pkgs.kdePackages.libkscreen
              # logger(1); systemd user services get no /usr/bin.
              pkgs.util-linux
            ];
            text = ''
              output=HDMI-A-1
              wantName=1920x1080@60
              wantRate=60

              log() { logger -t tv-display-mode-guard -- "$1"; }

              # Fail loudly rather than open. A guard that cannot run must not look
              # like a healthy display.
              if ! command -v kscreen-doctor >/dev/null; then
                log "FATAL: kscreen-doctor is not on PATH; the guard cannot run"
                exit 1
              fi

              # kscreen-doctor is a Qt app and aborts with no platform plugin. The
              # offscreen plugin hangs, so hand it KWin's real Wayland socket.
              if [ -e "$XDG_RUNTIME_DIR/wayland-0" ]; then
                WAYLAND_DISPLAY=wayland-0
              else
                WAYLAND_DISPLAY=""
                for sock in "$XDG_RUNTIME_DIR"/wayland-*; do
                  [ -e "$sock" ] || continue
                  WAYLAND_DISPLAY=$(basename "$sock")
                  break
                done
              fi
              export WAYLAND_DISPLAY

              # One token describing the situation. JSON mode names are rounded, so
              # 1920x1080@60 also names the 59.94Hz entries; the refresh rate is
              # what actually separates 60.00 from 59.94. The target is picked by
              # name+rate rather than a hardcoded mode id, because ids get
              # renumbered when the EDID mode list changes -- which is the whole
              # reason this service exists.
              #
              # wantRate is passed in rather than written into the jq program as a
              # literal 60, so the rate this service wants is stated once, next to
              # wantName, and the two cannot drift apart.
              probe() {
                kscreen-doctor -j 2>/dev/null | jq -r --arg o "$output" --arg w "$wantName" --argjson r "$wantRate" '
                  ([.outputs[] | select(.name == $o)][0]) as $out
                  | if $out == null then "absent"
                    else
                      ($out.modes[] | select(.id == $out.currentModeId)) as $cur
                      | ([$out.modes[]
                          | select(.name == $w and ((.refreshRate - $r) | fabs) < 0.01)]
                         | sort_by(.id | tonumber) | .[0].id) as $target
                      | if $out.connected != true then "disconnected"
                        elif $target == null then "unsupported"
                        elif ($cur.name == $w and (($cur.refreshRate - $r) | fabs) < 0.01) then "ok"
                        else "wrong \($target) \($cur.id) \($cur.name) \($cur.refreshRate)"
                        end
                    end'
              }

              # KWin may still be coming up when this first runs, so retry briefly.
              state=""
              attempt=0
              while [ "$attempt" -lt 10 ]; do
                state=$(probe) || state=""
                if [ -n "$state" ] && [ "$state" != "absent" ]; then
                  break
                fi
                attempt=$((attempt + 1))
                [ "$attempt" -lt 10 ] && sleep 6
              done

              # Log lines below interpolate $wantName only, never $wantName@$wantRate.
              # wantName is a kscreen mode name and already carries its own rate, so
              # the pair printed "1920x1080@60@60". wantRate is kept as a separate
              # number only because the JSON refreshRate comparison needs it.
              case "$state" in
                ok)
                  log "$output already at $wantName; nothing to do"
                  ;;
                disconnected)
                  log "$output not connected (TV off); nothing to do"
                  ;;
                unsupported)
                  log "$output does not offer $wantName; leaving the display alone"
                  ;;
                absent | "")
                  log "could not read the state of $output; leaving the display alone"
                  ;;
                wrong*)
                  # "wrong <targetId> <currentId> <currentName> <currentRate>"
                  read -r _ target currentId currentName currentRate <<<"$state"
                  log "output is on $currentName (mode $currentId, $currentRate Hz); restoring $wantName (mode $target)"
                  if timeout 20 kscreen-doctor "output.$output.enable" "output.$output.mode.$target"; then
                    log "restored $output to $wantName (mode $target)"
                  else
                    log "kscreen-doctor could not set mode $target; leaving the display alone"
                  fi
                  ;;
              esac
            '';
          };
        in
        {
          description = "Restore 1920x1080@60 on the TV if a kernel update changed the available EDID modes";
          # Driven by a timer rather than wantedBy: graphical-session.target is not
          # reliably pulled in on Plasma, whereas the user manager always starts.
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${script}/bin/tv-display-mode-guard";
            Environment = "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus";
          };
        };

      systemd.user.timers.tv-display-mode-guard = {
        description = "Check the TV is on 1920x1080@60 shortly after login";
        # Without this the timer stays "static" and never fires, even though the
        # user manager's timers.target is active. The systemd user manager starts
        # timers.target at login, which is what OnStartupSec counts from.
        wantedBy = [ "timers.target" ];
        timerConfig = {
          # 30s after the user manager starts, i.e. shortly after SDDM autologin.
          OnStartupSec = "30s";
          # Then keep checking. HDMI renegotiates on its own -- power-cycling the TV
          # or an AVR handshake can drop the mode mid-session, and the guard only
          # catches that if it looks again. The script never calls kscreen-doctor
          # unless the mode is actually wrong, so a correct display costs one JSON
          # query and no flicker.
          OnUnitActiveSec = "2h";
          AccuracySec = "10s";
          Unit = "tv-display-mode-guard.service";
        };
      };
    };
}
