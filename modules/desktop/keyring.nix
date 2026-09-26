# Secret Service provider for Noctalia's encrypted clipboard history: GNOME
# Keyring, which is both the D-Bus provider and what PAM unlocks at login.
# libsecret alone is not a provider. User settings live in ../home/noctalia.nix.
_: {
  flake.nixosModules.keyring = _: {
    services.gnome.gnome-keyring.enable = true;
    # No PAM line needed here: nixpkgs wires login.enableGnomeKeyring, and
    # greetd's auth is `substack login`, so the greeter inherits it.
    # Needed to set Login as the default keyring (see upstream docs).
    programs.seahorse.enable = true;
  };
}
