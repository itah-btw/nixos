# TV box: KDE Plasma Big Screen (10-foot UI) + SDDM auto-login.
# Phone-as-remote via KDE Connect (pair the phone app on the same wifi).
# Audio is explicit PipeWire + rtkit (Plasma does not enable it itself).
{ ... }:
{
  flake.nixosModules.bigscreen = { pkgs, lib, ... }: {
    services.desktopManager.plasma6.enable = true;

    # Big Screen session (verified: plasma-bigscreen-wayland.desktop).
    services.displayManager.sessionPackages = with pkgs.kdePackages; [
      plasma-bigscreen
    ];
    environment.systemPackages = with pkgs.kdePackages; [
      plasma-bigscreen
      kdeconnect-kde
    ];

    # Kiosk-style: boot straight into Big Screen, no password prompt.
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    services.displayManager.autoLogin = {
      enable = true;
      user = "itah";
    };
    services.displayManager.defaultSession = "plasma-bigscreen-wayland";

    # Phone-as-remote: KDE Connect ports 1714-1764 TCP+UDP.
    programs.kdeconnect.enable = true;
    networking.firewall.allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    networking.firewall.allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    security.rtkit.enable = true;

    # Bluetooth remotes / keyboards / gamepads.
    hardware.bluetooth.enable = true;
    security.polkit.enable = true;

    # No text-to-speech (global rule, see desktop/session.nix).
    # mkForce: Plasma's Orca module defaults speechd on.
    services.speechd.enable = lib.mkForce false;
  };
}
