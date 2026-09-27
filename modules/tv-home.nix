# TV home: Baloo off, ~/Downloads on the HDD, tuned mpv, Plasma power/lock.
# Deliberately not reusing base/aliases/apps/shell: those are hp-flavoured and
# do not fit an appliance.
{
  flake.homeManagerModules.tv-home = {
    # Indexing the media library for an index nothing queries would steal I/O
    # from playback. Plasma only rewrites this file from the File Search KCM;
    # force is needed because Plasma wrote it in the first session.
    home.file.".config/baloofilerc" = {
      force = true;
      text = ''
        [General]
        dbVersion=2
        Index Enabled=false
      '';
    };

    # Firefox has no policy for the download directory, so ~/Downloads is a
    # symlink to the HDD: downloads are large and read rarely, which suits a
    # 5400rpm disk and keeps multi-GB files off the NVMe. Only replaces an
    # empty directory. /mnt/media is mounted nofail (tv-media.nix) and is often
    # absent, since this box is switched off at the wall -- so it is checked
    # first, rather than silently writing downloads to the root disk.
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
        # Mesa's Vulkan driver on Ivy Bridge is incomplete; force the GL path.
        gpu-api=opengl
        # H.264/MPEG-2/VC-1 are the only codecs the HD 2500 decodes in hardware.
        # HEVC/VP9/AV1 fall back to the CPU, where mpv's decoder order already
        # picks the fastest available. Measured 1080p software decode 2.2x-3.7x
        # realtime; 4K is NOT viable (AV1 0.9x) -- never pick a 4K stream.
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
