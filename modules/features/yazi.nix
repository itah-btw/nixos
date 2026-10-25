{ ... }:
{
  flake.modules.homeManager.yazi = { pkgs, ... }: {
    programs.yazi = {
      enable = true;
      extraPackages = with pkgs; [ gnutar zip unzip p7zip unrar ouch ];
      plugins = {
        compress = pkgs.yaziPlugins.compress.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./yazi-compress.patch ];
        });
      };
      keymap = {
        mgr.prepend_keymap = [
          { on = [ "c" "a" "a" ]; run = "plugin compress"; desc = "Archive selected files"; }
          { on = [ "c" "a" "p" ]; run = "plugin compress -p"; desc = "Archive (password)"; }
          { on = [ "c" "a" "h" ]; run = "plugin compress -ph"; desc = "Archive (password+header)"; }
          { on = [ "c" "a" "l" ]; run = "plugin compress -l"; desc = "Archive (compression level)"; }
          { on = [ "c" "a" "u" ]; run = "plugin compress -phl"; desc = "Archive (all options)"; }
        ];
      };
    };
  };
}
