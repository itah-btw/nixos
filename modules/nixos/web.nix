{
  flake.nixosModules.web = { constants, ... }: {
    services.httpd = {
      enable = true;
      enablePHP = true;
      # Loopback only: docroot is user-writable and PHP-enabled. listenAddresses
      # defaults to ["*"]; guarded by httpd-loopback (checks.nix).
      virtualHosts.localhost = {
        documentRoot = "/var/www/html";
        listenAddresses = [ "127.0.0.1" ];
      };
    };
    systemd.tmpfiles.rules = [ "d /var/www/html 0755 ${constants.username} users -" ];
  };
}
