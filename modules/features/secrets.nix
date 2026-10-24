{ ... }:
{
  flake.modules.nixos.secrets = { ... }: {
    services.gnome.gnome-keyring.enable = true;

    # Unlock the keyring at login via the greeter's PAM service so Noctalia
    # (and other apps) can use org.freedesktop.secrets persistently.
    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
