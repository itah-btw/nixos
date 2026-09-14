{
  config,
  pkgs,
  ...
}: let
  # nixpkgs' catppuccin-gtk only ships the frappe flavor; grab the prebuilt
  # mocha-mauve GTK theme directly from the catppuccin/gtk release (the single
  # fixed desktop theme — no theme switcher).
  catppuccinMochaMauve =
    pkgs.runCommand "catppuccin-gtk-mocha-mauve"
    {
      src = pkgs.fetchurl {
        url = "https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-mocha-mauve-standard%2Bdefault.zip";
        sha256 = "cbacdac6161f98c315fb86740e21426ef6dda64f0ad69157cf28f3a1dda446fe";
      };
      nativeBuildInputs = [pkgs.unzip];
    }
    ''
      mkdir -p $out/share/themes
      unzip -q $src -d $out/share/themes
      rm -rf $out/share/themes/catppuccin-mocha-mauve-standard+default-hdpi \
             $out/share/themes/catppuccin-mocha-mauve-standard+default-xhdpi
      mv $out/share/themes/catppuccin-mocha-mauve-standard+default \
         $out/share/themes/catppuccin-mocha
    '';
  # nixpkgs' catppuccin-papirus-folders defaults to the blue accent, but the
  # whole desktop is Mocha mauve — override so the icon folders match.
in {
  environment.systemPackages = with pkgs; [
    android-tools
    catppuccin-cursors.mochaMauve
    (catppuccin-papirus-folders.override {
      flavor = "mocha";
      accent = "mauve";
    })
    btop
    bluetui
    brave-origin
    calcurse
    clipmenu
    dunst
    fastfetch
    fd
    feh
    ffmpegthumbnailer
    fzf
    glow
    imv
    jq
    libreoffice
    localsend
    lua-language-server
    lutgen
    libnotify
    maim
    mariadb
    mpv
    mycli
    netbeans
    nil
    obs-studio
    ouch
    pcmanfm
    p7zip
    poppler-utils
    pulsemixer
    catppuccinMochaMauve
    ripgrep
    stylua
    (tesseract.override {enableLanguages = ["eng" "ind"];})
    tumbler
    unar
    unrar
    ueberzugpp
    unzip
    (pkgs.writeShellScriptBin "vscode-json-languageserver" ''
      exec ${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server "$@"
    '')
    vscode-langservers-extracted
    xarchiver
    xdotool
    xclip
    yazi
    zathura
    zoxide
  ];

  services.gvfs.enable = true;

  # MariaDB is installed but NOT started automatically; use mycli when a
  # server is up, or start it on demand with `systemctl start mysql`.

  # LocalSend discovery + transfer port.
  networking.firewall.allowedTCPPorts = [53317];
  networking.firewall.allowedUDPPorts = [53317];

  # ADB/fastboot: systemd 258 handles uaccess rules automatically, so no
  # extra udev rules are needed — `android-tools` above provides the adb
  # command.
}
