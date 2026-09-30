{ inputs, lib, ... }:
{
  imports = [ inputs."treefmt-nix".flakeModule ];

  systems = [ "x86_64-linux" ];

  perSystem =
    { pkgs, ... }:
    let
      # ${./..} is the flake source as nix sees it -- tracked files only.
      # toString leaves a trailing "/." on it, which would make every
      # removeSuffix below a silent no-op.
      root = lib.removeSuffix "/." (toString ./..);
      # deadnix's --exclude does not prune a directory walk, so the file list is
      # built here instead and generated files are filtered out of it.
      nixFiles =
        let
          go =
            dir:
            lib.concatLists (
              lib.mapAttrsToList (
                name: type:
                let
                  path = "${dir}/${name}";
                in
                if type == "directory" then
                  go path
                else if lib.hasSuffix ".nix" name then
                  [ path ]
                else
                  [ ]
              ) (builtins.readDir dir)
            );
        in
        go root;
      isGenerated = p: lib.hasPrefix "hardware-configuration" (baseNameOf p);
      generated = lib.filter isGenerated nixFiles;
      lintable = lib.filter (p: !isGenerated p) nixFiles;
      fileList = lib.concatStringsSep "\n" lintable;
    in
    {
      # treefmt matches these globs against paths relative to its tree root,
      # so they have to be bare names, not store paths.
      treefmt.settings.global.excludes = map baseNameOf generated;
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
          status=0
          mapfile -t files <<'LINTFILES'
          ${fileList}
          LINTFILES

          check() {
            deadnix --fail "$@" || status=1
            # statix takes a single target, so it is walked one file at a time.
            for f in "$@"; do
              out=$(statix check --format errfmt "$f" 2>&1 || true)
              kept=$(printf '%s\n' "$out" | grep -v ':W:20:' || true)
              if [ -n "$kept" ]; then
                printf '%s\n' "$kept"
                status=1
              fi
            done
          }

          # Explicit target: lint exactly what was asked for.
          if [ "$#" -ge 1 ]; then check "$@"; else check "''${files[@]}"; fi

          exit "$status"
        '';
      };
    };
}
