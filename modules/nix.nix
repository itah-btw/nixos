{
  flake.nixosModules.nix = { lib, ... }: {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nix.settings.auto-optimise-store = true;
    nix.settings.trusted-users = [ "root" ];

    nix.settings.extra-substituters = [ "https://noctalia.cachix.org" ];
    nix.settings.extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];

    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "stremio-linux-shell"
        "proton-vpn"
        "proton-authenticator"
        "intel-vaapi-driver"
        "libva-utils"
      ];

    # filter never applies. `nclean` in aliases.nix prunes those instead.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    programs.nh.enable = true;
  };
}
