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

    # Umbriel's portal only implements ScreenCast + Screenshot. Without a
    # Settings backend, org.freedesktop.portal.Settings does not exist at all,
    # so apps that ask the portal for `prefers-color-scheme` never learn the
    # session is dark. The GTK backend supplies Settings (and FileChooser, so
    # Flatpak dialogs work later); keep Umbriel preferred for capture.
    xdg.portal.extraPortals = lib.mkForce [
      pkgs.xdg-desktop-portal-umbriel
      pkgs.xdg-desktop-portal-gtk
    ];
    xdg.portal.config.common = {
      default = [
        "umbriel"
        "gtk"
      ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "umbriel" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "umbriel" ];
      "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
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
  };
}
