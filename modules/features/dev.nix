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
      typescript-language-server
      vscode-langservers-extracted
      tailwindcss-language-server
      emmet-ls
      prettier
      eslint

      # PHP
      php
      phpactor

      # Lua
      lua
      lua-language-server
      stylua

      # Nix
      nil
      nixd
      nixfmt

      # Rust
      rustc
      cargo
      rust-analyzer
      rustfmt
      clippy
    ];
  };
}
