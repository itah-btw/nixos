# MariaDB server + MySQL clients.
#
# System side runs mariadb via services.mysql; user side installs
# mycli (TUI). NOTE: mysql-workbench removed 2026-09-20 — version 8.0.46
# fails to compile on nixos-unstable against boost 1.91
# (BOOST_STATIC_ASSERT removed, ninja target wbbase fails).
# Re-add once upstream fixes it; use DBeaver / Beekeeper Studio meanwhile.
{ ... }:
{
  flake.nixosModules.mariadb = { pkgs, lib, ... }: {
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      # Dev database: loopback only, never LAN-exposed.
      settings.mysqld.bind-address = "127.0.0.1";
    };

    # Manual start: installed but not auto-started at boot.
    # Start with: sudo systemctl start mysql
    # Stop with:  sudo systemctl stop mysql
    systemd.services.mysql.wantedBy = lib.mkForce [ ];
  };

  flake.homeManagerModules.mariadb = { pkgs, ... }: {
    home.packages = with pkgs; [
      mycli
    ];
  };
}
