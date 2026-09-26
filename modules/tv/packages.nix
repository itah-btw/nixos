# TV system packages + Firefox + offline docs trim.
# Ported from the box's configuration.nix (package set kept as-is).
{ ... }:
{
  flake.nixosModules.tv-packages =
    { pkgs, ... }:
    {
      programs.firefox.enable = true;

      environment.systemPackages = with pkgs; [
        stremio-linux-shell
        git
        libva-utils
        # For tv-media-disk-health (tv/media.nix). NixOS dropped
        # services.smartd, so smartctl is the only way left to read SMART
        # off this box's disks.
        smartmontools
        # Stremio bundles its own mpv and does read ~/.config/mpv/mpv.conf,
        # so the tuning in home/tv.nix is already live for it. This puts the
        # same tuned player on PATH directly, for pointing mpv at a file on
        # the media HDD.
        mpv
        opencode
      ];

      # The options index and the man pages are ~100 MB of store on a 119 GB
      # NVMe that also has to hold the store itself and every package on this
      # box. A TV reads neither; `nixos-option` and the git history of this
      # config are the documentation that actually gets used.
      documentation.nixos.enable = false;
      documentation.man.enable = false;
    };
}
