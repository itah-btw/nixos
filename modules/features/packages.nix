_: {
  flake.modules.nixos.packages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      # Nix / system management
      git
      nh
      nvd
      nix-tree

      # Shell and terminal helpers
      tealdeer
      duf
      ncdu
      wget
      wl-clipboard
      xdg-user-dirs
      wev

      # Development tools
      neovim
      lazygit
      gh
      python3
      jq
      opencode
      codex

      # CLI utilities
      ffmpeg
      p7zip
      zip
      poppler-utils
      fd
      ripgrep
      eza
      bat
      dust
      procs
      imagemagick
      resvg

      # GUI applications
      brave-origin
      proton-authenticator
      proton-vpn
      libreoffice
      vscode
      jabref
      imv
      mpv
      obs-studio
    ];
  };
}
