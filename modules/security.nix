{
  flake.nixosModules.security = {
    services.gnome.gnome-keyring.enable = true;
    programs.seahorse.enable = true;
    services.fprintd.enable = true;
    security.pam.services.login.fprintAuth = false;
    security.pam.services.greetd.fprintAuth = false;
  };
}
