# Fingerprint auth (fprintd). Deliberately password-only everywhere: greetd's
# auth stack is `substack login`, so enabling fprintAuth on `login` would also
# put a fingerprint reader on the login screen, and the keyring has to unlock
# from the same login password (see keyring.nix). There is no way to split the
# two -- this machine has no console login path anyway, only the greeter.
_: {
  flake.nixosModules.fingerprint = _: {
    services.fprintd.enable = true;
    # Stated on both stacks: `login` is what actually takes effect (greetd
    # sub-stacks it), `greetd` keeps the intent visible where it is read.
    security.pam.services.login.fprintAuth = false;
    security.pam.services.greetd.fprintAuth = false;
  };
}
