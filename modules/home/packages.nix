{
  flake.homeManagerModules.packages = { pkgs, ... }: {
    home.packages =
      with pkgs;
      [
        xdg-terminal-exec
        pavucontrol
        playerctl
        librewolf
        proton-authenticator
        proton-vpn
        localsend

        eza
        bat
        lazygit
        btop
        curl
        wl-clipboard

        ripgrep
        fd
        fzf
        unzip
        zip

        python3
        gcc
        cmake
        ninja
        gersemi
        clang-tools
        bear
        lldb
        valgrind
        cppcheck
        android-tools
        payload-dumper-go

        # nixpkgs builds these from one `rustPackages` set, so rustc/rustfmt/
        # clippy already share a version without pulling in rust-overlay.
        rustc
        cargo
        rust-analyzer
        rustfmt
        clippy

        mpv
        imv
        zathura
        obs-studio
        libreoffice

        vscode
        php
        netbeans
        llama-cpp
        lutgen

        nodejs
        typescript
        prettier
        eslint

        # vis-lspc resolves these by bare name on PATH; clangd and
        # rust-analyzer are already covered by clang-tools / rustc above,
        # the html/css/json servers by vscode-langservers-extracted below.
        typescript-language-server
        bash-language-server
        lua-language-server
        intelephense
        nil
        vscode-langservers-extracted

        mycli
      ]
      ++ [ pkgs.phpPackages.php-cs-fixer ];
  };
}
