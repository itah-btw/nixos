# TV home: Baloo off, ~/Downloads on the HDD, tuned mpv, Plasma power/lock.
# Identity comes from ./identity.nix. Deliberately NOT reusing home/base.nix,
# aliases.nix, apps.nix or shell.nix: those are hp-flavored (NH_FLAKE,
# rb -> #hp, fish login shell) and do not apply to the appliance box.
_: {
  flake.homeManagerModules.tv = _: {

    # Baloo is a desktop content search indexer. On a TV it would point a
    # 2-core CPU and the 5400rpm disk at crawling the media library for an
    # index nothing queries, stealing I/O from playback. Plasma only rewrites
    # this file from the File Search KCM, so managing it is safe. force:
    # Plasma already wrote it during the first session.
    home.file.".config/baloofilerc" = {
      force = true;
      text = ''
        [General]
        dbVersion=2
        Index Enabled=false
      '';
    };

    # Firefox has no enterprise policy for the download directory, so
    # ~/Downloads is a symlink to the HDD instead: downloads are large, written
    # once and read rarely, which is what a 5400rpm disk is good at, and it
    # keeps multi-GB downloads off the NVMe. Only replaces an empty directory.
    home.activation.downloadsOnMedia = ''
      mkdir -p /mnt/media/Downloads
      if [ -d "$HOME/Downloads" ] && [ ! -L "$HOME/Downloads" ]; then
        rmdir "$HOME/Downloads" \
          && ln -sfn /mnt/media/Downloads "$HOME/Downloads" \
          || echo "warning: ~/Downloads is not empty, leaving it alone" >&2
      else
        ln -sfn /mnt/media/Downloads "$HOME/Downloads"
      fi
    '';

    home.file.".config/mpv/mpv.conf" = {
      text = ''
        # Playback tuning for tv: i3-3240 (2c/4t) + Intel HD 2500 (Ivy Bridge).
        profile=fast
        # Mesa's Vulkan driver on Ivy Bridge is incomplete; force the GL path.
        gpu-api=opengl
        # H.264/MPEG-2/VC-1 are the only codecs the HD 2500 decodes in hardware.
        # HEVC/VP9/AV1 have no engine in this silicon and fall back to the CPU,
        # where mpv's own decoder order already picks the fastest available
        # (this build has no libde265). Measured 1080p software decode:
        # 2.2x-3.7x realtime. 4K is NOT viable (AV1 0.9x) -- never select a 4K
        # stream in Stremio. Numbers in the tv skill.
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
