{ ... }:
{
  flake.modules.homeManager.umbriel = { ... }: {
    xdg.configFile."umbriel/config.toml".source = ../umbriel/config.toml;
  };
}