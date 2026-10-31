_: {
  flake.modules.homeManager.btop =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = [ pkgs.btop ];

      home.activation.btopConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu
        target="${config.xdg.configHome}/btop/btop.conf"
        mkdir -p "$(dirname "$target")"
        if [ -L "$target" ]; then
          ${pkgs.coreutils}/bin/rm -f "$target"
        fi
        ${pkgs.coreutils}/bin/cp "${../btop/btop.conf}" "$target"
        ${pkgs.coreutils}/bin/chmod u+w "$target"
      '';
    };
}
