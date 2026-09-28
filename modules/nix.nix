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

    # A safety net for ordinary unreferenced paths. It cannot touch system
    # generations: every one in /nix/var/nix/profiles is a GC root, so the age
    # filter never applies. `nclean` in aliases.nix prunes those instead.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    # `nh os switch/test`, `nh clean`. See aliases.nix.
    programs.nh.enable = true;
  };
}
