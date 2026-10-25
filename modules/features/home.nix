{ config, ... }:
let
  homeModules = config.flake.modules.homeManager;
in
{
  flake.modules.nixos.home = { ... }: {
    home-manager.users.itah.imports = with homeModules; [ shell kitty yazi umbriel noctalia ];
  };
}
