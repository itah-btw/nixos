{
  config,
  lib,
  inputs,
  ...
}: {
  options = {
    # Lower-level NixOS modules for the `nixos` host, collected from feature
    # modules across this tree (dendritic pattern: shared by path, not by
    # specialArgs pass-through).
    modules.nixos = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [];
      description = "NixOS modules composing this machine.";
    };

    # Lower-level Home Manager modules for the single user.
    modules.home = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [];
      description = "Home Manager modules composing user `itah`.";
    };

    # The assembled, ready-to-activate NixOS configuration.
    # Must stay lazy (unspecified): anything would deep-force every NixOS
    # option while merging, erroring on unset ones such as `passthru`.
    build.nixos = lib.mkOption {
      type = lib.types.unspecified;
      internal = true;
      description = "Assembled NixOS configuration (nixosConfigurations.nixos).";
    };
  };

  config.build.nixos = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules =
      config.modules.nixos
      ++ [
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-bak";
            users.itah = {imports = config.modules.home;};
          };
        }
      ];
  };
}
