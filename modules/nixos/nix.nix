{
  flake.nixosModules.nix = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Never set `trusted-users` here. It is `types.listOf`, so it appends to
    # nixpkgs' own `[ "root" ]`; setting it yields `trusted-users = root root`.

    # gc frees store paths only; boot generations are pruned by `nclean` instead.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    # Hardlink dedup on the unit's own schedule; no dates line = upstream default.
    nix.optimise.automatic = true;

    # Global pkgs (home-manager useGlobalPkgs), so this list covers the HM
    # packages (vscode, intelephense) and fonts.nix's corefonts too.
    nixpkgs.config.allowUnfreePackages = [
      "corefonts"
      "intelephense"
      "vista-fonts"
      "vscode"
    ];

    programs.nh.enable = true;
  };
}
