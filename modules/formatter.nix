# Formatting (`nix fmt`) via treefmt: it discovers files itself, so the
# command works out of the box (plain nixfmt can't — `nix fmt` passes no
# paths and it ends up parsing empty stdin). Backend is nixpkgs' nixfmt
# (RFC style); the generated hardware-configuration.nix is excluded.
# Run `nix fmt` before committing.
{ inputs, ... }:
{
  imports = [ inputs."treefmt-nix".flakeModule ];

  # Enables ALL perSystem outputs (formatter, checks). Without this,
  # perSystem modules are silently dead and `nix flake check` passes
  # vacuously. Single-arch: matches `system` in hosts/hp.nix.
  systems = [ "x86_64-linux" ];

  perSystem = { ... }: {
    treefmt = {
      programs.nixfmt.enable = true;
      settings.global.excludes = [ "hardware-configuration.nix" ];
    };
  };
}
