{
  flake.nixosModules.mariadb = { pkgs, lib, ... }: {
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      settings.mysqld.bind-address = "127.0.0.1";
    };
    systemd.services.mysql.wantedBy = lib.mkForce [ ];
  };

  flake.homeManagerModules.mariadb = { pkgs, ... }: {
    home.packages = [ pkgs.mycli ];
  };
}
