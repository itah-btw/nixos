{ ... }:
{
  flake.modules.nixos.desktop = { config, lib, pkgs, ... }: {
    fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
    # Noctalia launches apps through `systemd-run --user`, which resolves the
    # executable using the service's PATH. The upstream module disables the
    # default path, and the minimal one lacks the system/user profiles, so
    # launcher entries fail with "No such file or directory" (and template
    # hooks cannot find bash). Give it the same profiles as a login shell.
    systemd.user.services.noctalia.path = [
      "/run/wrappers"
      "/run/current-system/sw"
      "/etc/profiles/per-user/${config.users.users.itah.name}"
      "/nix/var/nix/profiles/default"
    ];
    programs.umbriel.enable = true;

    # Umbriel's portal only implements ScreenCast + Screenshot. GTK backend
    # removed (no portal Settings/FileChooser); apps needing those fall back to
    # their own dialogs / gsettings. Umbriel stays preferred for capture.
    xdg.portal.extraPortals = lib.mkForce [
      pkgs.xdg-desktop-portal-umbriel
    ];
    xdg.portal.config.common = {
      default = [ "umbriel" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "umbriel" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "umbriel" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };

    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      systemd.target = "graphical-session.target";
      recommendedServices.enable = true;
    };

    services.displayManager.noctalia-greeter = {
      enable = true;
      settings = {
        cursor = { theme = "Adwaita"; size = 24; };
        keyboard.layout = "us";
      };
    };

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    services.speechd.enable = false;

    # Dark mode via gsettings/dconf (replaces the removed GTK portal's
    # Settings backend). Provides color-scheme for GTK4/libadwaita and
    # Electron apps that read gsettings.
    programs.dconf.enable = true;
  };
}
