{
  flake.homeManagerModules.clipboard =
    { pkgs, ... }:
    {
      # Clipboard history collector. A user service rather than an oxwm
      # autostart child, so WM reloads can't kill it; Restart covers the
      # login race where X isn't up yet when the user manager starts it.
      systemd.user.services.clipmenud = {
        Unit.Description = "Clipboard history collector";
        Service = {
          ExecStart = "${pkgs.clipmenu}/bin/clipmenud";
          Environment = [
            "DISPLAY=:0"
            # Default CM_DIR is under /tmp (wiped on reboot); keep history
            # on disk so it survives. Must match the Mod+V binding in
            # oxwm's config.lua (home/oxwm.nix).
            "CM_DIR=%h/.cache/clipmenu"
          ];
          Restart = "on-failure";
          RestartSec = "3s";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
