{ ... }:
{
  flake.modules.nixos.user = { pkgs, ... }: {
    users.users."itah" = {
      isNormalUser = true;
      description = "itah";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [ ];
    };
  };
}
