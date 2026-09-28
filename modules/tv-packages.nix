# TV system packages, plus a doc trim: the options index and man pages are
# ~100 MB of store a TV never reads.
{
  flake.nixosModules.tv-packages = { pkgs, ... }: {
    programs.firefox.enable = true;

    environment.systemPackages = with pkgs; [
      stremio-linux-shell
      # NixOS dropped services.smartd, so this is the only way to read SMART (tv-hdd.nix).
      smartmontools
      libva-utils
      # Stremio bundles its own mpv and reads ~/.config/mpv/mpv.conf, so the
      # tv-home.nix tuning is live for it.
      mpv
      yt-dlp
    ];

    documentation.nixos.enable = false;
    documentation.man.enable = false;
  };
}
