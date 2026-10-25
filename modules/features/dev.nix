{ ... }:
{
  flake.modules.nixos.dev = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      # C / C++
      gcc
      clang-tools
      cmake
      gnumake
      gdb

      # Web (HTML, CSS, JS, TS, React)
      nodejs
      typescript
      prettier
      eslint

      # PHP
      php

      # Lua
      lua
      stylua

      # Nix
      nixfmt

      # Rust
      rustc
      cargo
      rustfmt
      clippy
    ];
  };
}
