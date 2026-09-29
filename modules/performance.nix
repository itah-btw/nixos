{
  flake.nixosModules.performance = {
    zramSwap = {
      enable = true;
      memoryPercent = 30;
    };
    swapDevices = [
      {
        device = "/swapfile";
        size = 4096;
      }
    ];
  };
}
