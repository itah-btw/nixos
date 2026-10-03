{
  flake.nixosModules.system =
    {
      constants,
      inputs,
      lib,
      pkgs,
      ...
    }:
    {
      boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.loader.systemd-boot.enable = true;
      boot.loader.systemd-boot.configurationLimit = constants.generationKeep;
      boot.loader.efi.canTouchEfiVariables = true;

      # mesa 26.2.3 built by nixpkgs 7a0f122 initialises EGL for noctalia; the
      # b4fd65b1 rebuild of the *same version* returns EGL_NO_DISPLAY and the shell
      # dies at startup (nixpkgs#553285 is a different 26.2 regression, same series).
      # Pinned here so `nsu` can float nixpkgs without breaking the desktop.
      hardware.graphics.package =
        inputs.mesa-pinned.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mesa;

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      nix.settings.auto-optimise-store = true;

      # Never set `trusted-users` here. It is `types.listOf`, so it appends to
      # nixpkgs' own `[ "root" ]`; setting it yields `trusted-users = root root`.

      nix.settings.extra-substituters = [ constants.cachixSubstituter ];
      nix.settings.extra-trusted-public-keys = [ constants.cachixKey ];

      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "stremio-linux-shell"
        ];

      # filter never applies. `nclean` in home/scripts.nix prunes those instead.
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };

      programs.nh.enable = true;

      # noctalia's `recommendedServices` also provides NetworkManager on hp. This
      # line is the only one that reaches tv, which runs no noctalia.
      networking.networkmanager.enable = true;
      # tv-system.nix force-disables networking.wireless, so the iwd backend is
      # inert there.
      networking.networkmanager.wifi.backend = "iwd";
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
      security.sudo.wheelNeedsPassword = true;

      programs.fish.enable = true;

      environment.systemPackages = with pkgs; [
        git
        opencode
      ];
    };
}
