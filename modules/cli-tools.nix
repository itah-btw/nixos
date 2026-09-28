# Utilities reached for by name. Scripts a keybind spawns own their own
# dependencies: ocr.nix, brightness.nix, c-toolchain.nix.
{
  flake.homeManagerModules.cli-tools = { pkgs, ... }: {
    home.packages = with pkgs; [
      xdg-terminal-exec
      wl-clipboard
      brightnessctl
      playerctl
      pavucontrol
      curl
      fastfetch
      btop
      eza
      bat
      lazygit

      # Telescope live_grep/find_files, plus the CLI.
      ripgrep
      fd
      fzf
      # On the session PATH, not just via yazi: a template's apply.sh runs `zip -qr`.
      unzip
      zip
    ];
  };
}
