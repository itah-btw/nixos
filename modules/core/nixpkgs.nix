# nixpkgs unfree policy: only the packages actually unfree on this machine.
# If a new unfree package is added, extend the predicate — do not flip
# allowUnfree back on globally.
{ lib, ... }:
{
  flake.nixosModules.nixpkgs = {
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "stremio-linux-shell"
      ];
  };
}
