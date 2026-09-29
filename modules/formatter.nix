{ inputs, lib, ... }:
{
  imports = [ inputs."treefmt-nix".flakeModule ];

  systems = [ "x86_64-linux" ];

  perSystem =
    { pkgs, ... }:
    let
      # Generated, never hand-edited.
      excludes = [ "hardware-configuration*.nix" ];
      excludeArgs = lib.concatMapStringsSep " " (e: "--exclude ${e}") excludes;
    in
    {
      treefmt.settings.global.excludes = excludes;
      treefmt.programs.nixfmt.enable = true;
      treefmt.programs.stylua = {
        enable = true;
        settings = {
          indent_type = "Spaces";
          indent_width = 2;
        };
      };

      packages.lint = pkgs.writeShellApplication {
        name = "nix-lint";
        runtimeInputs = [
          pkgs.deadnix
          pkgs.statix
          pkgs.gnugrep
        ];
        text = ''
          target="''${1:-.}"
          status=0

          deadnix --fail ${excludeArgs} "$target" || status=1

          findings=$(statix check --format errfmt "$target" 2>&1 || true)
          kept=$(printf '%s\n' "$findings" | grep -v ':W:20:' || true)
          if [ -n "$kept" ]; then
            printf '%s\n' "$kept"
            status=1
          fi

          exit "$status"
        '';
      };
    };
}
