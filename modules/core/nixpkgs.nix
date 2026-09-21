# nixpkgs behavior: unfree allowance.
# (Overlays are wired by their own feature module in ../overlays/.)
{ ... }:
{
  flake.nixosModules.nixpkgs = {
    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;
  };
}
