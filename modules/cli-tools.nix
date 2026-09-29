{
  flake.homeManagerModules.cli-tools = { pkgs, ... }: {
    home.packages = with pkgs; [
      xdg-terminal-exec
      wl-clipboard
      playerctl
      pavucontrol
      curl
      fastfetch
      btop
      eza
      bat
      lazygit

      ripgrep
      fd
      fzf
      unzip
      zip
    ];
  };
}
