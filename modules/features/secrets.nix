{ ... }:
{
  flake.modules.nixos.secrets = { ... }: {
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
