# Nix client: flakes, the Noctalia cache, auto-GC, nh.
{
  flake.nixosModules.nix = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nix.settings.auto-optimise-store = true;
    nix.settings.trusted-users = [
      "root"
      "@wheel"
    ];

    # Mirrors flake.nix nixConfig for non-flake builds.
    nix.settings.extra-substituters = [ "https://noctalia.cachix.org" ];
    nix.settings.extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];

    # Rollback generations survive GC: they are linked, not old.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    # `nh os switch/test`, `nh clean`. See aliases.nix.
    programs.nh.enable = true;
  };
}
