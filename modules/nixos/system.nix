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

      nix.settings.extra-substituters = [ constants.cachixSubstituter ];
      nix.settings.extra-trusted-public-keys = [ constants.cachixKey ];

      # filter never applies. `nclean` in home/scripts.nix prunes those instead.
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };

      programs.nh.enable = true;

      services.flatpak.enable = true;

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
        flatpak
      ];
    };
}
