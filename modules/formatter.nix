# Canonical formatter for this tree (`nix fmt`).
# nixpkgs' nixfmt (RFC style). Run `nix fmt` before committing.
{ ... }:
{
  # Enables ALL perSystem outputs (formatter, checks). Without this,
  # perSystem modules are silently dead and `nix flake check` passes
  # vacuously. Single-arch: matches `system` in hosts/hp.nix.
  systems = [ "x86_64-linux" ];

  perSystem = { pkgs, ... }: {
    formatter = pkgs.nixfmt;
  };
}
