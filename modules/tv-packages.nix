# ~100 MB of store a TV never reads.
{
  flake.nixosModules.tv-packages = { pkgs, ... }: {
    programs.firefox.enable = true;

    environment.systemPackages = with pkgs; [
      stremio-linux-shell
      smartmontools
      libva-utils
      mpv
      yt-dlp
    ];

    documentation.nixos.enable = false;
    documentation.man.enable = false;
  };
}
