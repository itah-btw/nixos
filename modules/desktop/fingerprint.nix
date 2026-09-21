# Fingerprint auth (fprintd), everywhere EXCEPT the greeter.
#
# The greeter stays password-only on purpose: GNOME Keyring (see keyring.nix,
# backing Noctalia clipboard persistence) unlocks from the login password,
# which fingerprint auth never supplies. A fingerprint-only login would leave
# the keyring locked and clipboard history session-only.
#
# NixOS detail that forces the shape below: greetd's PAM auth stack is
# `substack login`, so it inherits whatever `login` has. `fprintAuth` defaults
# to `services.fprintd.enable` per service, and greetd uses custom rules
# (`useDefaultRules = false`) that ignore per-service flags — so flagging
# only `greetd` would be a no-op. Turning it off for `login` is the
# load-bearing setting that keeps the greeter password-only; sudo/su/polkit
# and friends keep the default (fingerprint on).
{ ... }:
{
  flake.nixosModules.fingerprint = { ... }: {
    services.fprintd.enable = true;

    # Greeter must stay password-only (keyring unlock). No-op on its own
    # (custom rules), kept to document intent if greetd ever uses defaults.
    security.pam.services.greetd.fprintAuth = false;
    # Load-bearing: greetd auth is `substack login`, so fingerprint must be
    # off here or it leaks into the greeter via the include.
    security.pam.services.login.fprintAuth = false;
  };
}
