{
  flake.nixosModules.nix =
    {
      constants,
      lib,
      ...
    }:
    {
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      nix.settings.auto-optimise-store = true;

      # Never set `trusted-users` here. It is `types.listOf`, so it appends to
      # nixpkgs' own `[ "root" ]`; setting it yields `trusted-users = root root`.

      nix.settings.extra-substituters = [ constants.cachixSubstituter ];
      nix.settings.extra-trusted-public-keys = [ constants.cachixKey ];

      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "stremio-linux-shell"
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
