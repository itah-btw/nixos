# MariaDB server (loopback-only, manual start) + mycli (TUI).
# mysql-workbench removed: 8.0.46 fails against boost 1.91 on unstable —
# re-add once upstream fixes it; use DBeaver / Beekeeper Studio meanwhile.
_: {
  flake.nixosModules.mariadb = { pkgs, lib, ... }: {
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      settings.mysqld.bind-address = "127.0.0.1";
    };

    # Installed but not auto-started at boot or by rebuild.
    # Manual start: sudo systemctl start mysql
    systemd.services.mysql.wantedBy = lib.mkForce [ ];
  };

  flake.homeManagerModules.mariadb = { pkgs, ... }: {
    home.packages = with pkgs; [
      mycli
    ];
  };
}
