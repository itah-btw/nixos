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
      wev
      polkit_gnome
      brave-origin
      proton-authenticator
      proton-vpn
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
      resvg
      libreoffice
      obs-studio
      vscode
      fastfetch
      btop
      zathura
    ];
  };
}
