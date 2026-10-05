{
  flake.nixosModules.web = { pkgs, ... }: {
    services.httpd = {
      enable = true;
      enablePHP = true;
      phpPackage = pkgs.php.override { ztsSupport = true; };
      virtualHosts.localhost.documentRoot = "/var/www/html";
    };
    systemd.tmpfiles.rules = [ "d /var/www/html 0755 itah users -" ];
  };
}
