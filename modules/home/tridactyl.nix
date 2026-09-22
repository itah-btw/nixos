# Tridactyl native messaging host: surface the store manifest at the path
# Firefox reads (~/.mozilla/native-messaging-hosts).
{ ... }:
{
  flake.homeManagerModules.tridactyl = { pkgs, ... }: {
    home.packages = [ pkgs.tridactyl-native ];

    home.file.".mozilla/native-messaging-hosts/tridactyl.json" = {
      source = "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";
    };
  };
}
