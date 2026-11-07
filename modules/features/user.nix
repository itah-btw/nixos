_: {
  flake.modules.nixos.user = { pkgs, ... }: {
    programs.fish.enable = true;

    users.users."itah" = {
      isNormalUser = true;
      description = "itah";
      shell = pkgs.fish;
      extraGroups = [
        "networkmanager"
        "wheel"
        "video"
        "render"
      ];
    };
  };
}
