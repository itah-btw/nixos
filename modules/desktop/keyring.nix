# Secret Service provider for Noctalia encrypted storage.
#
# Noctalia keeps clipboard history (and the calendar event cache) encrypted
# at rest under ~/.local/state/noctalia (clipboard/) and
# ~/.cache/noctalia/calendar, with the master key in Secret Service by
# default ([storage] key_source="secret-service"). Without a provider the
# key has nowhere to live, so history works for the session but is never
# written to disk — i.e. it does not survive reboot.
#
# This module provides GNOME Keyring (org.freedesktop.secrets via D-Bus +
# PAM auto-unlock) so the default key_source works. Upstream docs note
# libsecret alone is NOT a provider. System side only; the matching
# user-side settings ([storage], shell.clipboard_*) live in
# ../home/noctalia.nix.
{ ... }:
{
  flake.nixosModules.keyring = { ... }: {
    services.gnome.gnome-keyring.enable = true;

    # Our login path is greetd (noctalia-greeter). The upstream keyring
    # module only wires PAM for the `login` service, so opt greetd in
    # explicitly — this unlocks the Login keyring with the login password
    # and auto-starts the daemon.
    security.pam.services.greetd.enableGnomeKeyring = true;

    # Passwords and Keys GUI: needed to set Login as the default keyring
    # (multi-keyring setups otherwise relock after every reboot per
    # upstream docs).
    programs.seahorse.enable = true;
  };
}
