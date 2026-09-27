# Cursor theme, user-session side. Greeter half: session.nix. umbriel.nix reads
# these values back.
{
  flake.homeManagerModules.cursor = { pkgs, ... }: {
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
