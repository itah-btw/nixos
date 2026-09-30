{
  flake.homeManagerModules.packages = { pkgs, ... }: {
    home.packages =
      with pkgs;
      [
        # desktop
        xdg-terminal-exec
        pavucontrol
        playerctl
        firefox
        proton-authenticator
        proton-vpn
        localsend

        # shell
        eza
        bat
        lazygit
        fastfetch
        btop
        curl
        wl-clipboard

        # search and archives
        ripgrep
        fd
        fzf
        unzip
        zip

        # languages and toolchains
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

        # media
        mpv
        imv
        zathura
        obs-studio
        stremio-linux-shell
        libreoffice

        # workbench
        netbeans
        llama-cpp
        lutgen
      ]
      ++ [ pkgs.phpPackages.php-cs-fixer ];
  };
}
