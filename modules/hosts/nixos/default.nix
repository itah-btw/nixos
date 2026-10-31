{ config, inputs, ... }:
{
  # Every `flake.modules.nixos.<name>` under `modules/` is composed into the
  # host automatically. Adding a feature file is enough to enable it; the host
  # file stays free of a central feature list.
  flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.home-manager.nixosModules.home-manager
    ]
    ++ builtins.attrValues config.flake.modules.nixos;
  };
}
