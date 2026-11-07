_: {
  flake.modules.nixos.mariadb = { pkgs, ... }: {
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;

      # Local development only: never listen on the network.
      settings.mysqld = {
        "bind-address" = "127.0.0.1";
      };

      ensureDatabases = [ "dev" ];

      # Runs once, when the data directory is first initialised.
      # Creates the local `dev` user (password: dev) for app development.
      initialScript = ../mariadb/init.sql;
    };
  };
}
