# Kodi: plays the library on /mnt/media and fronts an IPTV provider. Stremio is
# the streaming source. Add-on sources are configured in Kodi.
{
  flake.nixosModules.tv-kodi = { pkgs, ... }: {
    # kodi-wayland, not kodi: the session is Wayland and the stock build is
    # X11. systemPackages so the .desktop reaches the Bigscreen app grid.
    environment.systemPackages = [ pkgs.kodi-wayland ];
  };

  flake.homeManagerModules.tv-kodi = { pkgs, ... }: {
    # Binary add-ons are not auto-discovered on NixOS, so link them in.
    home.file = {
      ".kodi/addons/pvr.iptvsimple".source =
        "${pkgs.kodiPackages.pvr-iptvsimple}/share/kodi/addons/pvr.iptvsimple";
      ".kodi/addons/inputstream.adaptive".source =
        "${pkgs.kodiPackages.inputstream-adaptive}/share/kodi/addons/inputstream.adaptive";
      # Shells out to yt-dlp from PATH (tv-packages.nix).
      ".kodi/addons/plugin.video.youtube".source =
        "${pkgs.kodiPackages.youtube}/share/kodi/addons/plugin.video.youtube";
    };
  };
}
