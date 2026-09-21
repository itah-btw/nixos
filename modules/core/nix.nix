# Nix client behavior: flakes + Noctalia binary cache.
{ ... }:
{
  flake.nixosModules.nix = {
    # Enable flakes and the new nix command (redundant once on a flake
    # setup, but keeps `nix` usable and documents the requirement).
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Deduplicate store entries on write (saves space, negligible cost).
    nix.settings.auto-optimise-store = true;

    # Let wheel members evaluate trusted options (e.g. --accept-flake-config
    # used by the rb/dry aliases) without a sudo password dance.
    nix.settings.trusted-users = [ "root" "@wheel" ];

    # Noctalia binary cache (matches flake.nix nixConfig, but also applies
    # when using legacy `nixos-rebuild` without `--flake`).
    nix.settings.extra-substituters = [ "https://noctalia.cachix.org" ];
    nix.settings.extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };
}
