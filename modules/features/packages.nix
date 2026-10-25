{ ... }:
{
  flake.modules.nixos.packages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      kitty
      vis
      wget
      opencode
      codex
      wl-clipboard
      wev
      brave-origin
      proton-authenticator
      proton-vpn
      yazi
      ffmpeg
      p7zip
      jq
      python3
      zip
      adw-gtk3
      poppler-utils
      fd
      ripgrep
      fzf
      zoxide
      imagemagick
      resvg
      libreoffice
      vscode
      fastfetch
      btop
      zathura
      wl-screenrec
    ];
  };
}
