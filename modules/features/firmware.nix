_: {
  flake.modules.nixos.firmware = _: {
    services.fwupd.enable = true;
    services.thermald.enable = true;
    hardware.enableRedistributableFirmware = true;
  };
}
