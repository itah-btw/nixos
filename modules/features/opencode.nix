{ inputs, ... }:
{
  flake.modules.nixos.opencode = _: {
    nixpkgs.overlays = [
      (_: prev: {
        opencode =
          let
            patched =
              builtins.replaceStrings
                [ "sha256-xfOVcw1+waLVNhFDwzOtzxrUSQEogvn88YomydOlhwc=" ]
                [ "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=" ]
                (builtins.readFile "${inputs.nixpkgs}/pkgs/by-name/op/opencode/package.nix");
          in
          (import (builtins.toFile "opencode-package.nix" patched)) {
            inherit (prev)
              lib
              stdenv
              bun
              darwin
              fetchFromGitHub
              installShellFiles
              makeBinaryWrapper
              models-dev
              nodejs
              nix-update-script
              ripgrep
              sysctl
              versionCheckHook
              wayland
              writableTmpDirAsHomeHook
              ;
          };
      })
    ];
  };
}
