{
  flake.homeManagerModules.fastfetch = {
    programs.fastfetch = {
      enable = true;
      settings = {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        logo = {
          type = "small";
          padding.top = 1;
        };
        display.separator = "  ";
        modules = [
          "break"
          {
            type = "title";
            color = {
              user = "#cba6f7";
              at = "#cba6f7";
              host = "#cba6f7";
            };
          }
          {
            type = "os";
            key = "os    ";
            keyColor = "red";
          }
          {
            type = "kernel";
            key = "kernel";
            keyColor = "green";
          }
          {
            type = "host";
            format = "{name} ({version})";
            key = "host  ";
            keyColor = "yellow";
          }
          {
            type = "packages";
            key = "pkgs  ";
            keyColor = "blue";
          }
          {
            type = "cpu";
            key = "cpu   ";
            keyColor = "magenta";
          }
          {
            type = "memory";
            key = "memory";
            keyColor = "cyan";
          }
          "break"
        ];
      };
    };
  };
}
