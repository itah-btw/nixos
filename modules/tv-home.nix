# TV home. Deliberately not reusing base/aliases/apps/shell: hp-flavoured.
{
  flake.homeManagerModules.tv-home = {
    # An index nothing queries would steal I/O from playback. force because
    # Plasma wrote this file itself in the first session.
    home.file.".config/baloofilerc" = {
      force = true;
      text = ''
        [General]
        dbVersion=2
        Index Enabled=false
      '';
    };

    # ~/Downloads on the HDD: large, read rarely, keeps multi-GB off the NVMe.
    # Only replaces an empty directory, and checks the nofail mount (tv-hdd.nix)
    # first -- this box is off at the wall, so it is often absent.
    home.activation.downloadsOnMedia = ''
      if [ -d /mnt/media ]; then
        mkdir -p /mnt/media/Downloads
        if [ -d "$HOME/Downloads" ] && [ ! -L "$HOME/Downloads" ]; then
          rmdir "$HOME/Downloads" \
            && ln -sfn /mnt/media/Downloads "$HOME/Downloads" \
            || echo "warning: ~/Downloads is not empty, leaving it alone" >&2
        else
          ln -sfn /mnt/media/Downloads "$HOME/Downloads"
        fi
      else
        echo "warning: /mnt/media is not mounted; leaving ~/Downloads alone" >&2
      fi
    '';

    # Playback tuning for tv: i3-3240 (2c/4t) + Intel HD 2500 (Ivy Bridge).
    home.file.".config/mpv/mpv.conf" = {
      text = ''
        profile=fast
        # Mesa's Vulkan driver is incomplete on Ivy Bridge; force GL.
        gpu-api=opengl
        # H.264/MPEG-2/VC-1 are the only hardware codecs; HEVC/VP9/AV1 fall to
        # the CPU, where mpv's decoder order already picks the fastest. Measured
        # 1080p software 2.2x-3.7x realtime, 4K NOT viable (AV1 0.9x).
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
