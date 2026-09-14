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
      # nixpkgs 0.12.0 has a known Lua-GC bug: keybind spawn strings are
      # stored by reference (getLuaString, not dupeLuaString), so temporaries
      # are collected before the keypress. The workaround lives in
      # home/itah/oxwm-config.lua (global CMD table keeps strings rooted).
    };

    # Uses the modesetting driver (default; xf86-video-intel fails to load
    # against this xorg-server: undefined symbol: vbeFree).
    displayManager.startx = {
      enable = true;
      generateScript = true;
    };

    # No compositor (oxwm#53).
  };

  # No display manager: login happens on tty1 via getty autologin,
  # X is started explicitly with `startx` (see home-manager bash profileExtra).
  services.displayManager.sddm.enable = lib.mkForce false;
  services.displayManager.gdm.enable = lib.mkForce false;

  # Bridge oxwm (sessionPackages-only module) to startx's generated xinitrc,
  # which sources `services.xserver.windowManager.session`.
  services.xserver.windowManager.session = [
    {
      name = "oxwm";
      start = ''
        ${config.services.xserver.windowManager.oxwm.package}/bin/oxwm &
        waitPID=$!
      '';
    }
  ];

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
    # Keybind debugging (e.g. verifying Mod+D reaches X): xev shows key
    # events, xprop shows window properties for oxwm.rule.add matching.
    xorg.xev
    xorg.xprop
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
