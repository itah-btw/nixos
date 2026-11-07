_: {
  flake.modules.nixos.web =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # nginx runs as the unprivileged `nginx` user, so it needs to be able to
      # traverse the home directory to serve files from ~/Projects. Group and
      # other users still cannot list or read the home directory itself.
      users.users.itah.homeMode = "0711";

      # Both units ship with ProtectHome=yes, which hides /home entirely.
      # This local development server intentionally serves files from ~/Projects.
      systemd.services.nginx.serviceConfig.ProtectHome = lib.mkForce false;
      systemd.services.phpfpm-web.serviceConfig.ProtectHome = lib.mkForce false;

      services.nginx = {
        enable = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;

        virtualHosts."localhost" = {
          # Local development only.
          listen = [
            {
              addr = "127.0.0.1";
              port = 80;
            }
            {
              addr = "[::1]";
              port = 80;
            }
          ];

          root = "/home/itah/Projects";

          locations."/" = {
            index = "index.php index.html";
            tryFiles = "$uri $uri/ /index.php?$query_string";
          };

          locations."~ \\.php$" = {
            extraConfig = ''
              fastcgi_pass unix:${config.services.phpfpm.pools.web.socket};
              fastcgi_index index.php;
            '';
          };
        };
      };

      services.phpfpm.pools.web = {
        user = "itah";
        group = "users";
        phpPackage = pkgs.php;

        settings = {
          "listen.owner" = "nginx";
          "listen.group" = "nginx";
          "listen.mode" = "0660";

          "pm" = "dynamic";
          "pm.max_children" = 10;
          "pm.start_servers" = 2;
          "pm.min_spare_servers" = 1;
          "pm.max_spare_servers" = 3;
          "catch_workers_output" = true;
        };
      };
    };
}
