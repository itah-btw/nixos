# User account.
{ ... }:
{
  flake.nixosModules.user = { pkgs, ... }: {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users."itah" = {
      isNormalUser = true;
      description = "itah";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      packages = with pkgs; [ ];
    };
  };
}
