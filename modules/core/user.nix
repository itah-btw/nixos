# User account.
{ ... }:
{
  flake.nixosModules.user = { pkgs, ... }: {
    users.users."itah" = {
      isNormalUser = true;
      description = "itah";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      packages = with pkgs; [ ];
    };
    # Explicit: wheel keeps prompting for a password on sudo (rb/rollback).
    security.sudo.wheelNeedsPassword = true;
  };
}
