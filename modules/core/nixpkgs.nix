# nixpkgs policy: allow unfree packages globally.
_: {
  flake.nixosModules.nixpkgs = {
    nixpkgs.config.allowUnfree = true;
  };
}
