# Fingerprint auth (fprintd) everywhere EXCEPT the greeter: greetd's PAM
# stack is `substack login`, so setting fprintAuth=false on `login` (and
# greetd, documenting intent) keeps the greeter password-only, ensuring the
# keyring unlocks from the login password (see keyring.nix).
{ ... }:
{
  flake.nixosModules.fingerprint = { ... }: {
    services.fprintd.enable = true;
    # Greeter must stay password-only (keyring unlock).
    security.pam.services.greetd.fprintAuth = false;
    security.pam.services.login.fprintAuth = false;
  };
}
