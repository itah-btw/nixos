{
  flake.nixosModules.system =
    {
      constants,
      pkgs,
      ...
    }:
    {
      zramSwap.enable = true;

      services.flatpak.enable = true;

      # iHD backend for the NPU-era iGPU. mpv's hwdec=auto (home/mpv.nix)
      # silently falls back to software without this.
      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
      ];
      environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

      # The bar and keybinds shell out to powerprofilesctl, which only
      # exists with the daemon running.
      services.power-profiles-daemon.enable = true;
      services.thermald.enable = true;

      # yazi and udisksctl have no mount backend without this; no DE
      # pulls it in on a WM-only box.
      services.udisks2.enable = true;

      time.timeZone = constants.timeZone;
      i18n.defaultLocale = constants.locale;
      # tty layout follows the same constant .xinitrc feeds to setxkbmap.
      console.keyMap = constants.layout;
      users.users.${constants.username} = {
        isNormalUser = true;
        description = constants.username;
        # audio/video/input come from logind's uaccess ACL while a seat session is
        # attached; the groups are what make a script or `systemd --user` unit
        # without one work too.
        extraGroups = [
          "audio"
          "input"
          "lp"
          "networkmanager"
          "render"
          "video"
          "wheel"
        ];
        shell = pkgs.fish;
      };

      programs.fish.enable = true;

      environment.systemPackages = with pkgs; [
        git
        opencode
      ];
    };
}
