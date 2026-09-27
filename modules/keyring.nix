# Secret Service for Noctalia's encrypted clipboard. GNOME Keyring is the
# D-Bus provider; libsecret alone is not one. User settings: noctalia.nix.
{
  flake.nixosModules.keyring = {
    services.gnome.gnome-keyring.enable = true;
    # Needed to set Login as the default keyring (upstream docs). PAM is already
    # wired by nixpkgs, and greetd inherits it via `substack login`.
    programs.seahorse.enable = true;
  };
}
