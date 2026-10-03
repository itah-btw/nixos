{
  flake.homeManagerModules.tridactyl = { pkgs, ... }: {
    home.file.".mozilla/native-messaging-hosts/tridactyl.json".source =
      "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";

    home.packages = [ pkgs.tridactyl-native ];
  };
}
