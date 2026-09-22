# Nix client behavior: flakes, Noctalia cache, auto-GC.
{ ... }:
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

    # Noctalia binary cache (mirrors flake.nix nixConfig for non-flake builds).
    nix.settings.extra-substituters = [ "https://noctalia.cachix.org" ];
    nix.settings.extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];

    # Weekly GC so the store does not fill up when aliases are forgotten.
    # Rollback generations survive because they are linked, not old.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
