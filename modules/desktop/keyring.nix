# Secret Service provider for Noctalia's encrypted clipboard history
# (GNOME Keyring via D-Bus + PAM auto-unlock; libsecret alone is not a
# provider). User settings live in ../home/noctalia.nix.
{ ... }:
{
  flake.nixosModules.keyring = { ... }: {
    services.gnome.gnome-keyring.enable = true;

    # greetd is our login path; the keyring module only wires PAM for
    # `login`, so opt greetd in to unlock with the login password.
    security.pam.services.greetd.enableGnomeKeyring = true;

    # Needed to set Login as the default keyring (see upstream docs).
    programs.seahorse.enable = true;
  };
}
