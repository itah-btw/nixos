{config, ...}: {
  # Collect the lower-level NixOS feature modules.
  config.modules.nixos = [
    ./../modules/nixos/nix.nix
    ./../modules/nixos/base.nix
    ./../modules/nixos/desktop.nix
    ./../modules/nixos/apps.nix
  ];
}
