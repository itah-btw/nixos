{ ... }:
{
  flake.modules.nixos.packages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      kitty
      vis
      wget
      opencode
      wl-clipboard
      proton-authenticator
      yazi
      ffmpeg
      p7zip
      jq
      poppler-utils
      fd
      ripgrep
      fzf
      zoxide
      imagemagick
      chafa
      obs-studio
      libreoffice
      vscode
      fastfetch
      btop
      zathura
    ];
  };
}
