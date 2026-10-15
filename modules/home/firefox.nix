{
  flake.homeManagerModules.firefox =
    { config, lib, ... }:
    let
      ffVersion = config.programs.firefox.package.version;
    in
    {
      programs.firefox = {
        enable = true;
        # Profile-independent: policies apply regardless of which profile
        # is default, unlike per-profile settings.
        policies.Preferences = {
          "media.ffmpeg.vaapi.enabled" = {
            Value = lib.versionOlder ffVersion "137.0.0";
            Status = "default";
          };
          "media.hardware-video-decoding.force-enabled" = {
            Value = lib.versionAtLeast ffVersion "137.0.0";
            Status = "default";
          };
          "media.rdd-ffmpeg.enabled" = {
            Value = lib.versionAtLeast ffVersion "137.0.0";
            Status = "default";
          };
          "gfx.x11-egl.force-enabled" = {
            Value = true;
            Status = "default";
          };
          "widget.dmabuf.force-enabled" = {
            Value = true;
            Status = "default";
          };
        };
      };
    };
}
