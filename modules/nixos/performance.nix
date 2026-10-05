{
  flake.nixosModules.performance = {
    zramSwap = {
      enable = true;
      memoryPercent = 50;
    };
  };
}
