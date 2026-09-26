# TV session: KDE Plasma Big Screen (10-foot UI) on Wayland, SDDM autologin.
# The long "why" comments in this directory live in the tv skill.
_: {
  flake.nixosModules.tv-bigscreen =
    { pkgs, lib, ... }:
    {
      # No Xorg has ever run here, so services.xserver bought nothing: another
      # server binary, its share of RAM on a 2-core box, and a second login
      # surface. Plasma 6 runs XWayland out of plasma-workspace rather than from
      # this option, so X11 *clients* (Stremio, xdg-desktop-portal-x11) are
      # unaffected. The xkb settings come from core/locale.nix, which this host
      # imports; Plasma stores the layout itself for Wayland anyway.
      services.xserver.enable = false;

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
      # VC-1/JPEG via the community i965 VA-API driver. No HEVC, VP9 or AV1
      # engine exists, so those decode on the CPU: 1080p is comfortable, 4K is
      # not (AV1 measured 0.9x realtime). Keep Stremio sources at 1080p; the
      # panel is 1080p anyway. Numbers in the tv skill.
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
