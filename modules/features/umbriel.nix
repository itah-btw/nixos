_: {
  flake.modules.homeManager.umbriel =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.activation.umbrielConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu
        target="${config.xdg.configHome}/umbriel/config.toml"
        mkdir -p "$(dirname "$target")"
        if [ -L "$target" ]; then
          ${pkgs.coreutils}/bin/rm -f "$target"
        fi
        ${pkgs.coreutils}/bin/cp "${../umbriel/config.toml}" "$target"
        ${pkgs.coreutils}/bin/chmod u+w "$target"
      '';
    };
}
