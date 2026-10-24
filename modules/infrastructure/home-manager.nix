{ ... }:
{
  flake.modules.nixos.homeManagerBase = { ... }: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.itah = { osConfig, ... }: {
        home.stateVersion = osConfig.system.stateVersion;
        home.username = "itah";
        home.homeDirectory = "/home/itah";
        programs.home-manager.enable = true;
      };
    };
  };
}
