# Declares the `flake.homeManagerModules` option that flake-parts does not
# provide itself (it ships nixosModules/nixosConfigurations/overlays only).
# Everything under `flake.` becomes a flake output, so `nix flake check` prints
# "unknown flake output 'homeManagerModules'". That warning is expected: the
# point is that the modules are exported and composable, not private.
{ lib, ... }:
{
  options.flake.homeManagerModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = "Home Manager modules, one per feature, composed by name in modules/hosts/*.nix.";
  };
}
