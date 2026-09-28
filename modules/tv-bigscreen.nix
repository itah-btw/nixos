# Plasma Big Screen (10-foot UI) on Wayland, SDDM autologin.
{
  flake.nixosModules.tv-bigscreen =
    {
      constants,
      lib,
      pkgs,
      ...
    }:
    {
      # X11 *clients* still work: Plasma 6 runs XWayland from plasma-workspace,
      # so this costs only a second login surface and some RAM.
      services.xserver.enable = false;

      services.displayManager = {
        defaultSession = "plasma-bigscreen-wayland";
        sessionPackages = [ pkgs.kdePackages.plasma-bigscreen ];
        sddm = {
          enable = true;
          settings.Autologin = {
            User = constants.username;
            Session = "plasma-bigscreen-wayland";
          };
        };
      };

      services.desktopManager.plasma6 = {
        enable = true;
        # No Qt 5 app here: Firefox is not Qt, Stremio is GTK4, mpv is Qt 6.
        enableQt5Integration = false;
      };
      xdg.portal.configPackages = [ pkgs.kdePackages.plasma-bigscreen ];

      # Optional apps a 10-foot appliance never opens. Kept anyway: the required
      # set, qtbase/qttools (xdg-mime, xdg-terminal, qdbus kdeconnect), and konsole.
      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        kwin-x11
        kate
        khelpcenter
        krdp
        plasma-workspace-wallpapers
        union
      ];

      programs.kdeconnect.enable = true;

      # Intel HD 2500 (Ivy Bridge) via the community i965 VA-API driver. No
      # HEVC/VP9/AV1 engine: 1080p is fine, 4K is not (AV1 0.9x realtime).
      hardware.graphics.extraPackages = [ pkgs.intel-vaapi-driver ];

      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      services.orca.enable = lib.mkForce false;
      services.speechd.enable = lib.mkForce false;
    };
}
