{ ... }:
{
  flake.modules.homeManager.kitty = { ... }: {
    xdg.configFile."kitty/kitty.conf".source = ../kitty/kitty.conf;
  };
}
