_: {
  flake.modules.nixos.maintenance = _: {
    services.fstrim.enable = true;

    # Monitor NVMe/SATA drive health and warn early.
    services.smartd.enable = true;

    boot.loader.systemd-boot.configurationLimit = 20;

    # Keep the Nix store and generation list bounded without a custom timer.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-generations +20";
      persistent = true;
      randomizedDelaySec = "1h";
    };
  };
}
