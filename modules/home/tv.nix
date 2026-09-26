# TV home: Baloo off, ~/Downloads on the HDD, tuned mpv, Plasma power/lock.
# Ported verbatim from the box's home.nix. Deliberately NOT reusing
# home/base.nix, aliases, apps or shell: those are hp-flavored (NH_FLAKE,
# rb -> #hp, fish login shell) and do not apply to the appliance box.
{ ... }:
{
  flake.homeManagerModules.tv = { ... }: {
    home.username = "itah";
    home.homeDirectory = "/home/itah";
    home.stateVersion = "26.11";
    programs.home-manager.enable = true;

    # Baloo is a desktop content search indexer. On a TV it would point a
    # 2-core CPU and the 5400rpm disk at crawling the media library for an index
    # nothing ever queries, stealing I/O from playback. Plasma only rewrites this
    # file when the File Search KCM is used, so managing it is safe.
    home.file.".config/baloofilerc" = {
      # Plasma already wrote this file during the first session, so it has to be
      # taken over rather than treated as a fresh link.
      force = true;
      text = ''
        [General]
        dbVersion=2
        Index Enabled=false
      '';
    };

    # Firefox has no enterprise policy for the default download directory, so
    # ~/Downloads is a symlink to the 500 GB HDD instead. Downloads are large,
    # written once and read rarely -- exactly the workload a 5400rpm disk handles
    # well -- and it keeps multi-GB downloads off the NVMe.
    home.activation.downloadsOnMedia =
      let
        target = "/mnt/media/Downloads";
      in
      ''
        mkdir -p "${target}"
        if [ -d "$HOME/Downloads" ] && [ ! -L "$HOME/Downloads" ]; then
          # Only replaces an empty directory; anything already downloaded stays put.
          rmdir "$HOME/Downloads" \
            && ln -sfn "${target}" "$HOME/Downloads" \
            || echo "warning: ~/Downloads is not empty, leaving it alone" >&2
        else
          ln -sfn "${target}" "$HOME/Downloads"
        fi
      '';

    home.file.".config/mpv/mpv.conf" = {
      text = ''
        # Playback tuning for tv: i3-3240 (2c/4t) + Intel HD 2500 (Ivy Bridge).
        profile=fast
        # Mesa's Vulkan driver on Ivy Bridge is incomplete; force the GL path.
        gpu-api=opengl
        # H.264/MPEG-2/VC-1 are the only codecs the HD 2500 decodes in hardware.
        # HEVC/VP9/AV1 have no engine in this silicon and always fall back to the
        # CPU. mpv's own decoder order already picks the fastest one available
        # here (av1=libdav1d, vp9=native, hevc=native; this build has no
        # libde265, and 0.41 dropped the --vd-lavc override), so leave it alone.
        # Measured 1080p software decode: 2.2x-3.7x realtime. 4K is NOT viable
        # (AV1 0.9x realtime) -- never select a 4K stream in Stremio.
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
