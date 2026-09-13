{
  config,
  lib,
  pkgs,
  ...
}: {
  services.xserver = {
    enable = true;

    windowManager.oxwm = {
      enable = true;
    };

    displayManager.startx = {
      enable = true;
      generateScript = true;
    };
  };

  # No display manager: login happens on tty1 via getty autologin,
  # X is started explicitly with `startx` (see home-manager bash profileExtra).
  services.displayManager.sddm.enable = lib.mkForce false;
  services.displayManager.gdm.enable = lib.mkForce false;

  # Bridge oxwm (sessionPackages-only module) to startx's generated xinitrc,
  # which sources `services.xserver.windowManager.session`.
  services.xserver.windowManager.session = lib.singleton {
    name = "oxwm";
    start = ''
      ${config.services.xserver.windowManager.oxwm.package}/bin/oxwm &
      waitPID=$!
    '';
  };

  # No TTS / accessibility stack: enabling xserver flips
  # `services.speechd.enable` on via graphical defaults (which pulls
  # speechd -> espeak-ng -> mbrola -> ~630MB mbrola-voices).
  services.speechd.enable = false;

  # Brightness keys: install brightnessctl's udev rules so the `video`
  # group gets write access to /sys/class/backlight/*/brightness
  # (itah is in `video`, see base.nix).
  services.udev.packages = with pkgs; [brightnessctl];

  # Touchpad: natural (inverted) scrolling via libinput. Applies at next
  # X server start (i.e. next tty1 login).
  services.libinput.touchpad.naturalScrolling = true;

  # Auto-login on tty1 instead of a graphical greeter.
  services.getty.autologinUser = "itah";

  environment.systemPackages = with pkgs; [
    dmenu
    # Alacritty terminal (GPU-accelerated, themed via alacritty.toml, shows the
    # Xcursor theme natively — no cursor patching needed like st had).
    alacritty
    xterm
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
