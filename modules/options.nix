# Flake-output options this config needs beyond what flake-parts
# declares itself (`flake.nixosModules`, `flake.nixosConfigurations`,
# `flake.overlays` are provided by flake-parts; `flake.homeManagerModules`
# is not, so without this declaration its per-feature definitions cannot
# be merged and evaluation fails).
#
# Cf. the dendritic "not declaring options" anti-pattern: model the infra
# explicitly instead of squeezing into only pre-existing options.
{ lib, ... }:
{
  options.flake.homeManagerModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = { };
    description = "Home Manager modules, one per feature, composed by name in hosts/nixos.nix.";
  };
}
