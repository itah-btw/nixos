{ ... }:
{
  flake.modules.nixos.networking = { ... }: {
    networking.hostName = "nixos";
    networking.networkmanager.enable = true;
  };
}
