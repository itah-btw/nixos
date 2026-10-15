{
  flake.nixosModules.system =
    {
      constants,
      pkgs,
      ...
    }:
    {
      boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.loader.systemd-boot.enable = true;
      boot.loader.systemd-boot.configurationLimit = constants.generationKeep;
      boot.loader.efi.canTouchEfiVariables = true;

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      nix.settings.auto-optimise-store = true;

      # Never set `trusted-users` here. It is `types.listOf`, so it appends to
      # nixpkgs' own `[ "root" ]`; setting it yields `trusted-users = root root`.

      # gc frees store paths only; boot generations are pruned by `nclean` instead.
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };

      programs.nh.enable = true;

      zramSwap = {
        enable = true;
        memoryPercent = 50;
      };

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

      # NetworkManager lives here directly (it used to ride along with
      # noctalia's `recommendedServices`, removed with that stack).
      networking.networkmanager.enable = true;
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = false;
      };

      time.timeZone = constants.timeZone;
      i18n.defaultLocale = constants.locale;
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
