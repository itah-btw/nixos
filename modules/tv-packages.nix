# TV system packages, and the offline documentation trim: the options index and
# man pages are ~100 MB of store that a TV never reads.
{
  flake.nixosModules.tv-packages = { pkgs, ... }: {
    programs.firefox.enable = true;

    environment.systemPackages = with pkgs; [
      stremio-linux-shell
      # NixOS dropped services.smartd, so smartctl is the only way left to read
      # SMART off this box (hdd.nix).
      smartmontools
      libva-utils
      # Stremio bundles its own mpv and reads ~/.config/mpv/mpv.conf, so the
      # tuning in tv-home.nix is live for it; this puts it on PATH directly.
      mpv
      yt-dlp
    ];

    documentation.nixos.enable = false;
    documentation.man.enable = false;
  };
}
