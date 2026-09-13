{
  config,
  pkgs,
  ...
}: {
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
    picom
    poppler-utils
    pulsemixer
    qogir-icon-theme
    qogir-theme
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
    # Desktop theme switcher: `theme apply <tokyonight|catppuccin|gruvbox>`
    # rethemes oxwm bar/borders/dmenu, alacritty, dunst, and the wallpaper.
    (pkgs.writeShellScriptBin "theme" (builtins.readFile ./theme.sh))
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
