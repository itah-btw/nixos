{
  flake.nixosModules.wifi = {
    # hp-only: tv-system.nix force-disables networking.wireless, so this was
    # inert there.
    networking.networkmanager.wifi.backend = "iwd";
  };
}
