{config, ...}: {
  # This is the machine feature: host identity and generated hardware config.
  config.modules.nixos = [
    ./../hosts/nixos/hardware-configuration.nix
    {
      networking.hostName = "nixos";
      system.stateVersion = "26.11";
    }
  ];
}
