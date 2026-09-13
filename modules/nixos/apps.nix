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
  # Papirus with Catppuccin Mocha (mauve) folders: the nixpkgs
  # catppuccin-papirus-folders package only ships stock Papirus themes, so
  # recolor them at build time with the upstream papirus-folders script plus
  # the catppuccin/papirus-folders folder SVGs (color cat-mocha-mauve).
  catppuccinPapirus =
    pkgs.runCommand "papirus-catppuccin-mocha-mauve"
    {
      iconThemes = pkgs.papirus-icon-theme;
      fork = pkgs.fetchurl {
        url = "https://github.com/catppuccin/papirus-folders/archive/f83671d17ea67e335b34f8028a7e6d78bca735d7.zip";
        sha256 = "sha256-LfQcAd62tDKsisd0wAcBmoArK4GyWs++ObA4aJbwPD8=";
      };
      script = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders";
        sha256 = "sha256-swpoSKAGkDAqzP/AUFSSGLCxFNMXiyi9OhaJGBeCGwY=";
      };
      nativeBuildInputs = [pkgs.unzip pkgs.bash pkgs.coreutils];
    }
    ''
      mkdir -p $out/share/icons

      mkdir -p work/fork
      unzip -q $fork -d work/fork

      for theme in Papirus Papirus-Dark Papirus-Light; do
        cp -rL "$iconThemes/share/icons/$theme" "$out/share/icons/$theme"
        chmod -R u+rwX "$out/share/icons/$theme"
        for sz in 22x22 24x24 32x32 48x48 64x64; do
          cp -f work/fork/*/src/$sz/places/*.svg "$out/share/icons/$theme/$sz/places/"
        done
        DISABLE_UPDATE_ICON_CACHE=1 bash $script -t "$out/share/icons/$theme" -C cat-mocha-mauve -o
      done
    '';
in {
  environment.systemPackages = with pkgs; [
    android-tools
    bibata-cursors
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
    libnotify
    maim
    mariadb
    mpv
    mycli
    netbeans
    nil
    obs-studio
    ouch
    p7zip
    catppuccinPapirus
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

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  services.gvfs.enable = true;

  # MariaDB is installed but NOT started automatically; use mycli when a
  # server is up, or start it on demand with `systemctl start mysql`.
  services.mysql.enable = false;

  # LocalSend discovery + transfer port.
  networking.firewall.allowedTCPPorts = [53317];
  networking.firewall.allowedUDPPorts = [53317];

  # ADB/fastboot device access for the active seat user (no adb module or
  # android-udev-rules package in nixpkgs, so cover common vendor IDs here;
  # run `lsusb` and add yours if a device is still not visible).
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0bb4", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fce", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1004", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0b05", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0502", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="413c", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="04dd", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0482", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="04c5", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="17ef", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="19d2", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2a70", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2ae5", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="22d9", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2d95", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1782", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1d97", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0489", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2314", MODE="0660", TAG+="uaccess"
  '';
}
