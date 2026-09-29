{
  flake.homeManagerModules.tv-home =
    { constants, pkgs, ... }:
    {
      home.file.".config/baloofilerc" = {
        force = true;
        text = ''
          [General]
          dbVersion=2
          Index Enabled=false
        '';
      };

      home.activation.downloadsOnMedia = ''
          media="${constants.mediaMount}"
          if ${pkgs.util-linux}/bin/mountpoint -q "$media"; then
          mkdir -p "$media/Downloads"
          if [ -d "$HOME/Downloads" ] && [ ! -L "$HOME/Downloads" ]; then
            rmdir "$HOME/Downloads" \
              && ln -sfn "$media/Downloads" "$HOME/Downloads" \
              || echo "warning: ~/Downloads is not empty, leaving it alone" >&2
          else
            ln -sfn "$media/Downloads" "$HOME/Downloads"
          fi
        else
          echo "warning: $media is not mounted; leaving ~/Downloads alone" >&2
        fi
      '';

      home.file.".config/mpv/mpv.conf" = {
        text = ''
          profile=fast
          gpu-api=opengl
          hwdec=vaapi
          vd-queue-enable=yes
          vd-queue-max-bytes=64MiB
          vd-queue-max-secs=1
          vd-lavc-threads=0
          scale=bilinear
          dscale=bilinear
          osc=no
          osd-bar=no
          cache=yes
          demuxer-max-bytes=256MiB
          demuxer-max-back-bytes=32MiB
        '';
      };

      programs.plasma = {
        enable = true;

        powerdevil.AC = {
          autoSuspend.action = "nothing";
          dimDisplay.enable = false;
          turnOffDisplay.idleTimeout = "never";
        };

        kscreenlocker = {
          autoLock = false;
          lockOnStartup = false;
          lockOnResume = false;
        };
      };
    };
}
