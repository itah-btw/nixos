# `nix fmt` via treefmt; `systems` also enables the other perSystem outputs
# (checks). Backends: nixfmt (style) plus deadnix/statix (dead code), so
# `nix fmt` is also the dead-code pass -- run it before committing.
{ inputs, ... }:
{
  imports = [ inputs."treefmt-nix".flakeModule ];

  systems = [ "x86_64-linux" ];

  perSystem = _: {
    treefmt = {
      programs = {
        nixfmt.enable = true;
        deadnix.enable = true;
        statix = {
          enable = true;
          # W20 rewrites `services.foo.bar = ...` into nested attrsets. That is
          # a matter of taste and hurts readability in NixOS modules, so the
          # linter is off; every other statix fix (e.g. `{ ... }:` -> `_:`) is
          # applied automatically.
          disabled-lints = [ "repeated_keys" ];
        };
      };

      # Generated, never hand-edited: nixfmt would reformat them and deadnix
      # would strip their unused lambda args.
      settings.global.excludes = [ "hardware-configuration*.nix" ];
    };
  };
}
