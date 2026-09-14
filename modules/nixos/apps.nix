{
  lib,
  pkgs,
  ...
}: let
  # Mocha-mauve GTK theme: nixpkgs' catppuccin-gtk only ships frappe, so pull the
  # prebuilt mocha release directly (single fixed desktop theme, no switcher).
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

  # Papirus icon folders: default blue accent overridden to match the mauve desktop.
  catppuccinPapirusFolders = pkgs.catppuccin-papirus-folders.override {
    flavor = "mocha";
    accent = "mauve";
  };
in {
  environment.systemPackages = with pkgs; [
    android-tools
    catppuccin-cursors.mochaMauve
    catppuccinPapirusFolders
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
  ];

  services.gvfs.enable = true;

  # MariaDB (local dev): user itah, password hash (plaintext '1909' not in repo).
  # Connect: mycli -u itah -p -h localhost  |  mariadb -u itah -p -h localhost
  # To rotate: mariadb -u root -e "SELECT PASSWORD('new-password')" then replace the hash below.
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    initialScript = pkgs.writeText "mysql-init.sql" ''
      CREATE USER IF NOT EXISTS 'itah'@'localhost' IDENTIFIED BY PASSWORD '*B7D45478225E8AA0DD9B0498AD9AE98F958F5324';
      CREATE USER IF NOT EXISTS 'itah'@'127.0.0.1' IDENTIFIED BY PASSWORD '*B7D45478225E8AA0DD9B0498AD9AE98F958F5324';
      GRANT ALL PRIVILEGES ON *.* TO 'itah'@'localhost' WITH GRANT OPTION;
      GRANT ALL PRIVILEGES ON *.* TO 'itah'@'127.0.0.1' WITH GRANT OPTION;
      FLUSH PRIVILEGES;
    '';
  };

  systemd.services.mysql.wantedBy = lib.mkForce []; # on-demand only: `sudo systemctl start mysql`

  # LocalSend discovery + transfer port.
  networking.firewall.allowedTCPPorts = [53317];
  networking.firewall.allowedUDPPorts = [53317];
}
