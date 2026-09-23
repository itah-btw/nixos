# User account.
{ ... }:
{
  flake.nixosModules.user = { ... }: {
    users.users."itah" = {
      isNormalUser = true;
      description = "itah";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
    # Explicit: wheel keeps prompting for a password on sudo (rb/rollback).
    security.sudo.wheelNeedsPassword = true;
  };
}
