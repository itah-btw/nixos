# Declares the `flake.homeManagerModules` option that flake-parts does not
# provide itself (it ships nixosModules/nixosConfigurations/overlays only).
{ lib, ... }:
{
  options.flake.homeManagerModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = "Home Manager modules, one per feature, composed by name in hosts/hp.nix.";
  };
}
