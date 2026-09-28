# `nix fmt` (nixfmt + stylua) and `nix run .#lint` (deadnix + statix, check-only).
# Fixers are kept out of the formatter: folded in, `push` swept unrelated auto-fixes
# from other modules into whatever was being committed. stylua only reflows.
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
      # The hand-written Lua in nvim/, which also makes checks.treefmt a Lua
      # syntax check -- stylua parses what it formats.
      treefmt.programs.stylua = {
        enable = true;
        # Spaces at width 2, to match the Nix.
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

          # W20 (repeated_keys) rewrites `services.foo.bar = ...` into nested
          # attrsets, which hurts readability in NixOS modules, so it is not a
          # finding. Filtered here because statix's own `disabled` config
          # suppresses W20 only for two-occurrence spans.
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
