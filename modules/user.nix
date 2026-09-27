# The user account. Username comes from flake.constants.
{
  flake.nixosModules.user = { constants, ... }: {
    users.users.${constants.username} = {
      isNormalUser = true;
      description = constants.username;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
    # wheel keeps prompting for a password on sudo (rb, rollback).
    security.sudo.wheelNeedsPassword = true;
  };
}
