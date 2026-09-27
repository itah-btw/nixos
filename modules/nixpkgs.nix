# nixpkgs policy: unfree allowed on both hosts.
{
  flake.nixosModules.nixpkgs = {
    nixpkgs.config.allowUnfree = true;
  };
}
