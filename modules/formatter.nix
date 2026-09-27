# `nix fmt` (nixfmt only) and `nix lint` (deadnix + statix, check-only). Kept
# apart because the latter two are fixers: folded into the formatter, `push`
# swept unrelated auto-fixes into whatever was being committed.
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
