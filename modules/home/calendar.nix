{
  flake.homeManagerModules.calendar =
    {
      lib,
      pkgs,
      ...
    }:
    let
      # Appointment reminders: khal has no daemon, so a timer polls for
      # events starting within 15 minutes and notifies once per event (state
      # files in the runtime dir vanish on reboot, re-arming everything).
      khalRemind = pkgs.writeShellApplication {
        name = "khal-remind";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.khal
          pkgs.libnotify
        ];
        text = ''
          state="''${XDG_RUNTIME_DIR:-/tmp}/khal-notified"
          mkdir -p "$state"
          now=$(date +%s)
          limit=$((now + 900))
          khal list --format "{start-time} | {title}" today --notstarted 2>/dev/null | while IFS= read -r line; do
            case "$line" in
              *"|"*) ;;
              *) continue ;;
            esac
            start="''${line%% | *}"
            title="''${line#* | }"
            epoch=$(date -d "$start" +%s 2>/dev/null) || continue
            [ "$epoch" -le "$limit" ] || continue
            [ "$epoch" -ge "$now" ] || continue
            id=$(printf '%s' "$line" | sha256sum | cut -d' ' -f1)
            [ -f "$state/$id" ] && continue
            notify-send "Calendar" "$title" || true
            touch "$state/$id"
          done || true
        '';
      };
    in
    {
      xdg.configFile."khal/config".text = ''
        [calendars]
            [[home]]
                path = ~/.calendars/home
                color = light blue
            [[google-personal]]
                path = ~/.calendars/google-personal
                color = light green
            [[google-family]]
                path = ~/.calendars/google-family
                color = yellow
            [[google-holidays]]
                path = ~/.calendars/google-holidays
                color = light magenta
            [[f1]]
                path = ~/.calendars/f1
                color = light cyan
            [[manutd]]
                path = ~/.calendars/manutd
                color = light red
        [default]
            default_calendar = home
            highlight_event_days = True
        [locale]
            timeformat = "%H:%M"
            dateformat = "%d/%m/%Y"
            longdateformat = "%d/%m/%Y"
            datetimeformat = "%d/%m/%Y %H:%M"
            longdatetimeformat = "%d/%m/%Y %H:%M"
        [highlight_days]
            default_color = yellow
      '';

      home.file.".calendars/home/.keep".text = "";

      # vdirsyncer config is seeded once as a real file (never a store
      # symlink): OAuth identifiers must stay out of the Nix store, and
      # `discover` writes found collections back into it. Every content line
      # sits at column 0: vdirsyncer reads indented lines as continuations
      # of the previous value (config parse error).
      home.activation.seedVdirsyncer = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        cfgFile="$HOME/.config/vdirsyncer/config"
        if [ ! -f "$cfgFile" ]; then
          mkdir -p "$HOME/.config/vdirsyncer"
          # Strip indentation: vdirsyncer reads indented lines as
          # continuations, so the seed is whitespace-proof either way.
          sed 's/^ *//' > "$cfgFile" <<'EOF'
        [general]
        status_path = "~/.local/share/vdirsyncer/status/"

          [pair google_sync]
          a = "local"
          b = "remote"
          collections = ["from b"]

        [storage local]
        type = "filesystem"
        path = "~/.calendars/"
        fileext = ".ics"

        [storage remote]
        type = "google_calendar"
        client_id = ""
        client_secret = ""
        token_file = "~/.vdirsyncer-tokens"
        EOF
                fi
      '';

      # Appointment reminders poll via the timer below; see khalRemind above.
      systemd.user.services.khal-remind = {
        Unit.Description = "khal appointment reminders";
        Service = {
          Type = "oneshot";
          ExecStart = "${khalRemind}/bin/khal-remind";
        };
      };

      systemd.user.timers.khal-remind = {
        Unit.Description = "Check upcoming appointments every few minutes";
        Timer = {
          OnBootSec = "2min";
          OnUnitActiveSec = "5min";
        };
        Install.WantedBy = [ "timers.target" ];
      };

      # Push/pull CalDAV both ways; failures (offline, unconfigured) just
      # retry next round, so an empty template config is harmless.
      systemd.user.services.vdirsyncer = {
        Unit.Description = "Sync calendars with CalDAV";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer sync";
        };
      };

      systemd.user.timers.vdirsyncer = {
        Unit.Description = "Sync calendars every 10 minutes";
        Timer = {
          OnBootSec = "2min";
          OnUnitActiveSec = "10min";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
