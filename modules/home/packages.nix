{
  flake.homeManagerModules.packages = { pkgs, ... }: {
    home.packages =
      with pkgs;
      [
        xdg-terminal-exec
        pavucontrol
        playerctl
        firefox
        proton-authenticator
        proton-vpn
        localsend

        eza
        bat
        lazygit
        fastfetch
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
        stremio-linux-shell
        libreoffice

        netbeans
        llama-cpp
        lutgen

        mycli
      ]
      ++ [ pkgs.phpPackages.php-cs-fixer ];
  };
}
