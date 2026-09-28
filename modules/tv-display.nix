# Re-assert 1920x1080@60 on the TV (user service + timer). The EDID prefers
# 1280x720@50 and the kernel is mainline-weekly, so a mode-list shift drops the
# panel to 720p50 silently.
_: {
  flake.nixosModules.tv-display =
    { pkgs, ... }:
    {
      # KWin owns kwinoutputconfig.json. No-op when already correct or the TV is off.
      systemd.user.services.tv-display-mode-guard =
        let
          script = pkgs.writeShellApplication {
            name = "tv-display-mode-guard";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.jq
              # kscreen-doctor is in libkscreen, NOT kscreen: with kdePackages.kscreen
              # the guard would fail open, logging success.
              pkgs.kdePackages.libkscreen
              # logger(1); user services get no /usr/bin.
              pkgs.util-linux
            ];
            text = ''
              output=HDMI-A-1
              wantName=1920x1080@60
              wantRate=60

              log() { logger -t tv-display-mode-guard -- "$1"; }

              # Fail loudly, not open: a guard that cannot run is not a healthy display.
              if ! command -v kscreen-doctor >/dev/null; then
                log "FATAL: kscreen-doctor is not on PATH; the guard cannot run"
                exit 1
              fi

              # A Qt app: with no platform plugin it aborts, offscreen it hangs.
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

              # Pick the target by name+rate, never a hardcoded id: ids get renumbered
              # when the EDID list changes. The rate matters too -- mode names are
              # rounded, so 1920x1080@60 also names the 59.94Hz entries.
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

              # KWin may still be starting.
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

              # $wantName only, never $wantName@$wantRate: it already carries its rate.
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
          # Timer-driven, not wantedBy: Plasma does not reliably pull in
          # graphical-session.target, the user manager always is.
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${script}/bin/tv-display-mode-guard";
            Environment = "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus";
          };
        };

      systemd.user.timers.tv-display-mode-guard = {
        description = "Check the TV is on 1920x1080@60 shortly after login";
        # Without this the timer stays "static" and never fires, though timers.target
        # is active: the user manager starts it at login, which OnStartupSec counts from.
        wantedBy = [ "timers.target" ];
        timerConfig = {
          # 30s after the user manager starts, i.e. just after SDDM autologin.
          OnStartupSec = "30s";
          # Then keep checking: HDMI renegotiates on its own (TV power-cycle, AVR
          # handshake). A correct display costs one JSON query and no flicker.
          OnUnitActiveSec = "2h";
          AccuracySec = "10s";
          Unit = "tv-display-mode-guard.service";
        };
      };
    };
}
