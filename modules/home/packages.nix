{
  # Bare tools live here; configured packages live with their config, and
  # helpers keep their own runtimeInputs (wrappers see only those on PATH).
  flake.homeManagerModules.packages = { pkgs, ... }: {
    home.packages = with pkgs; [
      xdg-terminal-exec
      proton-authenticator
      proton-vpn
      localsend

      bluetui
      brightnessctl
      clipmenu
      feh
      libnotify
      maim
      slop
      wiremix
      xclip
      xdotool

      khal
      vdirsyncer

      eza
      bat
      lazygit
      btop
      curl

      ripgrep
      fd
      fzf
      jq
      unzip
      zip

      python3
      gcc
      mold
      cmake
      ninja
      gersemi
      clang-tools
      bear
      lldb
      valgrind
      cppcheck
      shellcheck
      android-tools
      payload-dumper-go

      # nixpkgs builds these from one `rustPackages` set, so rustc/rustfmt/
      # clippy already share a version without pulling in rust-overlay.
      rustc
      cargo
      rust-analyzer
      rustfmt
      clippy

      imv
      zathura
      obs-studio
      libreoffice
      yt-dlp

      vscode
      php
      netbeans
      llama-cpp
      lutgen

      nodejs
      typescript
      prettier
      eslint

      # tony-nvim's lsp.lua resolves these by bare name on PATH; clangd comes
      # with clang-tools above (rust-analyzer has its own entry below),
      # the html/css/json servers with vscode-langservers-extracted below.
      typescript-language-server
      bash-language-server
      lua-language-server
      intelephense
      nil
      vscode-langservers-extracted

      mycli
      phpPackages.php-cs-fixer
    ];
  };
}
