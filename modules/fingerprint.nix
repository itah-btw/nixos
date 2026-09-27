# fprintd, password-only: greetd's auth is `substack login`, so enabling it
# there would put a fingerprint reader on the login screen too, and the keyring
# has to unlock from the same password (keyring.nix).
{
  flake.nixosModules.fingerprint = {
    services.fprintd.enable = true;
    security.pam.services.login.fprintAuth = false;
    security.pam.services.greetd.fprintAuth = false;
  };
}
