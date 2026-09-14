{
  config,
  pkgs,
  ...
}: {
  services.xserver = {
    enable = true;

    windowManager.oxwm = {
      enable = true;
      # 0.12.0 Lua-GC bug: keybind spawn strings are stored by reference; the
      # workaround lives in home/itah/oxwm-config.lua — never revert to inline temporaries.
    };

    # No compositor (oxwm#53): autologin on tty1, `startx` runs oxwm.
    displayManager.startx = {
      enable = true;
      generateScript = true;
    };
  };

  # Bridge oxwm (sessionPackages-only module) into startx's generated xinitrc.
  services.xserver.windowManager.session = [
    {
      name = "oxwm";
      start = ''
        ${config.services.xserver.windowManager.oxwm.package}/bin/oxwm &
        waitPID=$!
      '';
    }
  ];

  # No TTS/speechd (enabling xserver would pull ~630MB mbrola-voices).
  services.speechd.enable = false;

  # brightnessctl udev rules: gives the `video` group backlight write access.
  services.udev.packages = with pkgs; [brightnessctl];

  services.libinput.touchpad.naturalScrolling = true;

  services.getty.autologinUser = "itah";

  environment.systemPackages = with pkgs; [
    dmenu
    alacritty
    xterm
    xev
    xprop
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
