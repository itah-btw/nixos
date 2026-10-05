{
  flake.nixosModules.web = { pkgs, ... }: {
    services.httpd = {
      enable = true;
      enablePHP = true;
      virtualHosts.localhost.documentRoot = "/var/www/html";
    };
    systemd.tmpfiles.rules = [ "d /var/www/html 0755 itah users -" ];
  };
}
