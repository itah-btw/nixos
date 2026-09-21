# nixpkgs behavior: unfree allowance.
# (If an overlay is ever needed: modules/overlays/<name>.nix exposes it as
# flake.overlays.<name> AND wires nixpkgs.overlays via its own
# flake.nixosModules.<name>. None currently — do not add stale examples.)
{ ... }:
{
  flake.nixosModules.nixpkgs = {
    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;
  };
}
