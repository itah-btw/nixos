{ config, ... }:
let
  homeModules = config.flake.modules.homeManager;
in
{
  flake.modules.nixos.home = { ... }: {
    home-manager.users.itah.imports = with homeModules; [ shell umbriel ];
  };

  flake.modules.homeManager.umbriel = { ... }: {
    xdg.configFile."umbriel/config.toml".source = ../umbriel/config.toml;
  };
}
