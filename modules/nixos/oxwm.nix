{
  flake.nixosModules.oxwm =
    { pkgs, ... }:
    {
      services.xserver.enable = true;
      services.xserver.windowManager.oxwm.enable = true;

      # clickfinger makes 2-finger physical click Button3; lrm keeps 2-finger tap right-click.
      services.libinput.touchpad.clickMethod = "clickfinger";
      services.libinput.touchpad.tappingButtonMap = "lrm";

      # Dummy pseudo-DM declaring manual startx usage. Load-bearing: without
      # it nixpkgs defaults displayManager.lightdm to true whenever X is on
      # and no other session starter is detected.
      services.xserver.displayManager.startx.enable = true;

      # The session starts through startx (getty autologin on tty1 execs it
      # from the login shell), which reads only /etc/X11/xorg.conf; without
      # it Xorg misses every input driver.
      services.xserver.exportConfiguration = true;

      # startx itself; kept as an explicit dependency of the session above.
      environment.systemPackages = [ pkgs.xinit ];
    };
}
