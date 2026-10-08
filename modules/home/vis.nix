{
  flake.homeManagerModules.vis =
    { pkgs, ... }:
    let
      # Not packaged in nixpkgs. Pinned to a rev rather than `main` so a
      # rebuild cannot silently pull a different plugin.
      lspcTarball = pkgs.fetchurl {
        url = "https://codeberg.org/muhq/vis-lspc/archive/fadfe996f86b9fbb189255ae7fb7433519ba15f3.tar.gz";
        hash = "sha256-ZIxAtAm11K7x2CRn4ZBXLaSyETZoR/4iyaHoqYQjlb8=";
      };
      # The store path is interpolated by Nix rather than left as a shell
      # `$src`: the generic builder does not export `src` into the build
      # environment, so the shell form reads as `tar -xzf -C $out` and tar
      # then treats $out as the archive.
      visLspc = pkgs.runCommand "vis-lspc" { src = lspcTarball; } ''
        mkdir -p $out
        tar -xzf ${lspcTarball} -C $out --strip-components=1
        chmod +x $out/tools/find-upwards
      '';
    in
    {
      home.packages = [ pkgs.vis ];

      home.file.".config/vis/visrc.lua".source = ../../vis/visrc.lua;
      home.file.".config/vis/themes/noctalia.lua".source = ../../vis/themes/noctalia.lua;
      # vis 0.9 ships no nix lexer; VIS_PATH includes ~/.config, so this is
      # where plugins/filetype.lua's searchpath looks for lexers/nix.lua.
      home.file.".config/vis/lexers/nix.lua".source = ../../vis/lexers/nix.lua;

      # find-upwards locates the project root; it stays executable through the
      # store symlink, which is why visLspc chmods it rather than shipping it
      # as plain source.
      home.file = {
        ".config/vis/plugins/vis-lspc/bindings.lua".source = "${visLspc}/bindings.lua";
        ".config/vis/plugins/vis-lspc/init.lua".source = "${visLspc}/init.lua";
        ".config/vis/plugins/vis-lspc/json.lua".source = "${visLspc}/json.lua";
        ".config/vis/plugins/vis-lspc/log.lua".source = "${visLspc}/log.lua";
        ".config/vis/plugins/vis-lspc/lspc.lua".source = "${visLspc}/lspc.lua";
        ".config/vis/plugins/vis-lspc/parser.lua".source = "${visLspc}/parser.lua";
        ".config/vis/plugins/vis-lspc/settings.lua".source = "${visLspc}/settings.lua";
        ".config/vis/plugins/vis-lspc/supported-servers.lua".source = "${visLspc}/supported-servers.lua";
        ".config/vis/plugins/vis-lspc/util.lua".source = "${visLspc}/util.lua";
        ".config/vis/plugins/vis-lspc/tools/find-upwards".source = "${visLspc}/tools/find-upwards";
      };
    };
}
