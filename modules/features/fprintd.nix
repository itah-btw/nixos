{ ... }:
{
  flake.modules.nixos.fprintd = { ... }: {
    services.fprintd.enable = true;
  };
}
