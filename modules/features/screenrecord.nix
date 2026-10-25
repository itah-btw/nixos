{ ... }:
{
  flake.modules.nixos.screenrecord = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      (writeShellApplication {
        name = "screenrecord-toggle";
        runtimeInputs = [ wl-screenrec procps libnotify coreutils ];
        text = ''
          if pgrep -x wl-screenrec >/dev/null; then
            pkill -INT wl-screenrec
            notify-send "Recording" "Stopped" 2>/dev/null || true
          else
            outdir="$HOME/Videos"
            mkdir -p "$outdir"
            outfile="$outdir/screenrecord-$(date +%Y%m%d-%H%M%S).mp4"
            nohup wl-screenrec -f "$outfile" --audio >/dev/null 2>&1 &
            disown
            notify-send "Recording" "Started: $outfile" 2>/dev/null || true
          fi
        '';
      })
      (writeShellApplication {
        name = "screenrecord-region";
        runtimeInputs = [ wl-screenrec slurp procps libnotify coreutils ];
        text = ''
          region="$(slurp)" || exit 1
          outdir="$HOME/Videos"
          mkdir -p "$outdir"
          outfile="$outdir/screenrecord-$(date +%Y%m%d-%H%M%S).mp4"
          nohup wl-screenrec -g "$region" -f "$outfile" --audio >/dev/null 2>&1 &
          disown
          notify-send "Recording" "Started: $outfile" 2>/dev/null || true
        '';
      })
    ];
  };
}
