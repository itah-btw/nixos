# `nix fmt` via treefmt (nixfmt backend); excludes generated hardware file.
# `systems` also enables all perSystem outputs (formatter + checks).
{ inputs, ... }:
{
  imports = [ inputs."treefmt-nix".flakeModule ];

  systems = [ "x86_64-linux" ];

  perSystem = { ... }: {
    treefmt = {
      programs.nixfmt.enable = true;
      settings.global.excludes = [ "hardware-configuration.nix" ];
    };
  };
}
