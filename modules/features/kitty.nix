_: {
  flake.modules.homeManager.kitty =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = [ pkgs.kitty ];

      home.activation.kittyConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu
        target="${config.xdg.configHome}/kitty/kitty.conf"
        mkdir -p "$(dirname "$target")"
        if [ -L "$target" ]; then
          ${pkgs.coreutils}/bin/rm -f "$target"
        fi
        ${pkgs.coreutils}/bin/cp "${../kitty/kitty.conf}" "$target"
        ${pkgs.coreutils}/bin/chmod u+w "$target"
      '';
    };
}
