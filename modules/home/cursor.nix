# Cursor theme (Bibata Modern Ice) — user session side.
# System/greeter side lives in ../desktop/session.nix (cursorTheme.package +
# settings.cursor.theme — greeter cannot see home-only fonts/cursors).
# Compositor side lives in ./umbriel.nix (input.cursor.theme).
{ ... }:
{
  flake.homeManagerModules.cursor =
    { pkgs, ... }:
    {
      # HM installs the package, sets XCURSOR_THEME/SIZE, writes
      # ~/.icons + XDG icons, and (via gtk.enable) defaults
      # gtk.cursorTheme so GTK apps follow the same theme.
      # gtk.enable requires gtk.enable=true (see apps.nix).
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
