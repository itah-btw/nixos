{
  # Bare tools live here; configured packages live with their config, and
  # helpers keep their own runtimeInputs (wrappers see only those on PATH).
  flake.homeManagerModules.packages = { pkgs, ... }: {
    home.packages = with pkgs; [
      android-tools

      # tony-nvim's lsp.lua resolves these by bare name on PATH; clangd comes
      # with clang-tools, the html/css/json servers with vscode-langservers-extracted.
      bash-language-server
      bat
      bear
      bluetui
      brightnessctl
      btop

      # nixpkgs builds these from one `rustPackages` set, so rustc/rustfmt/
      # clippy already share a version without pulling in rust-overlay.
      cargo
      clang-tools
      clipmenu
      clippy
      cmake
      cppcheck
      curl
      eslint
      eza
      fastfetch
      fd
      feh
      fzf
      gcc
      gersemi
      imv
      intelephense
      jq
      khal
      lazygit
      libnotify
      libreoffice
      llama-cpp
      lldb
      localsend
      lua-language-server
      lutgen
      maim
      mold
      mycli
      netbeans
      nil
      ninja
      nodejs
      obs-studio
      payload-dumper-go
      php
      phpPackages.php-cs-fixer
      prettier
      proton-authenticator
      proton-vpn
      python3
      ripgrep
      rust-analyzer
      rustc
      rustfmt
      shellcheck
      slop
      typescript
      typescript-language-server
      unzip
      valgrind
      vdirsyncer
      vscode
      vscode-langservers-extracted
      wiremix
      xclip
      xdg-terminal-exec
      xdotool
      yt-dlp
      zathura
      zip
    ];
  };
}
