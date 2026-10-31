_: {
  flake.modules.nixos.dev = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      # C / C++
      gcc
      clang
      clang-tools
      cmake
      gnumake
      gdb

      # Web (HTML, CSS, JS, TS)
      nodejs
      typescript
      typescript-language-server
      vscode-langservers-extracted
      prettier
      eslint

      # PHP
      php
      php85Packages.composer
      php85Packages.php-cs-fixer
      phpactor

      # Java
      jdk
      maven
      gradle
      jdt-language-server

      # Lua
      lua
      stylua

      # Nix
      nixfmt
      nixd
      statix
      deadnix

      # Rust
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
    ];

    programs.nix-ld.enable = true;
  };
}