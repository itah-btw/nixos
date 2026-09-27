# Tridactyl native messaging host, at the path Firefox reads.
{
  flake.homeManagerModules.tridactyl = { pkgs, ... }: {
    home.packages = [ pkgs.tridactyl-native ];
    home.file.".mozilla/native-messaging-hosts/tridactyl.json".source =
      "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";
  };
}
