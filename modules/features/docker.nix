_: {
  flake.modules.nixos.docker = { pkgs, ... }: {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      extraPackages = [ pkgs.docker-compose ];
    };

    # The WARP containers need a TUN device.
    boot.kernelModules = [ "tun" ];

    users.users.itah.extraGroups = [ "docker" ];

    environment.systemPackages = [ pkgs.docker-compose ];
  };
}
