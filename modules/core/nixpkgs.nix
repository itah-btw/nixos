# nixpkgs policy: allow unfree packages globally.
{ ... }:
{
  flake.nixosModules.nixpkgs = {
    nixpkgs.config.allowUnfree = true;
  };
}
