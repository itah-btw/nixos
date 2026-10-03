{
  flake.nixosModules.mariadb = { pkgs, lib, ... }: {
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      settings.mysqld.bind-address = "127.0.0.1";
    };
    # Installed and configured, started only when asked (`mdb-up`). Clearing
    # wantedBy needs mkForce: the module sets it to multi-user.target at normal
    # priority. `enable = false` would be stronger but also unstartable.
    systemd.services.mysql.wantedBy = lib.mkForce [ ];
  };
}
