# Cursor theme (Bibata Modern Ice), user-session side. System/greeter side
# lives in desktop/session.nix; compositor side in umbriel.nix.
{ ... }:
{
  flake.homeManagerModules.cursor =
    { pkgs, ... }:
    {
      home.pointerCursor = {
        enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 24;
        gtk.enable = true;
        x11.enable = true;
      };
    };
}
