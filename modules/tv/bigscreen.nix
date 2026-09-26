# TV session: KDE Plasma Big Screen (10-foot UI) on Wayland, SDDM autologin.
# Ported verbatim from the box's configuration.nix; comments kept because
# each one records a paid-for debugging session (see tv skill).
{ ... }:
{
  flake.nixosModules.bigscreen =
    { pkgs, lib, ... }:
    {
      # The session is Plasma Bigscreen on Wayland and no Xorg has ever run
      # here, so services.xserver bought nothing: another server binary, its
      # share of RAM on a 2-core box, and a second login surface. Plasma 6
      # runs XWayland out of plasma-workspace rather than from this option,
      # so X11 *clients* -- Stremio's Electron UI, anything routed through
      # xdg-desktop-portal-x11 -- are unaffected. Plasma stores the keyboard
      # layout itself for Wayland, so the xkb settings go with it; the
      # session is a US layout either way.
      services.xserver = {
        enable = false;
        # Mirrors core/locale.nix (xkb is the single source of truth there).
        xkb = {
          layout = "us";
          variant = "";
        };
      };

      services.displayManager = {
        defaultSession = "plasma-bigscreen-wayland";
        sessionPackages = [ pkgs.kdePackages.plasma-bigscreen ];
        sddm = {
          enable = true;
          settings.Autologin = {
            User = "itah";
            Session = "plasma-bigscreen-wayland";
          };
        };
      };

      services.desktopManager.plasma6.enable = true;
      xdg.portal.configPackages = [ pkgs.kdePackages.plasma-bigscreen ];

      programs.kdeconnect.enable = true;

      # Intel HD 2500 (Gen6, Ivy Bridge) hardware decode for H.264/MPEG-2/
      # VC-1/JPEG via the community i965 VA-API driver. Verified: 1080p H.264
      # High drops from ~10.5 to ~0.15 CPU-seconds per 20s of video.
      #
      # The GPU has no HEVC, VP9 or AV1 engine, so those always decode on the
      # CPU. Measured on the i3-3240 (2c/4t, no AVX2) at 1080p: HEVC 2.2x
      # realtime, AV1/dav1d 2.8x, VP9 3.7x -- comfortable. 4K is not viable:
      # AV1 measured 0.9x realtime and 4K HEVC extrapolates past 100% of both
      # cores. Keep Stremio sources at 1080p; the panel is 1080p anyway.
      hardware.graphics.extraPackages = [ pkgs.intel-vaapi-driver ];

      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      # No text-to-speech (global rule). mkForce: Plasma's Orca module
      # defaults speechd on. Enforced by the host-generic no-tts guard.
      services.speechd.enable = lib.mkForce false;
    };
}
