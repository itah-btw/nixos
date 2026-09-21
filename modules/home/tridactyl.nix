# Tridactyl (vim-like Firefox extension) native messaging host.
# FireFox reads per-user hosts from ~/.mozilla/native-messaging-hosts;
# the nixpkgs package ships its manifest already pointing at the store
# binary (lib/mozilla/native-messaging-hosts/tridactyl.json), so we only
# surface it at the path the browser actually looks up.
{ ... }:
{
  flake.homeManagerModules.tridactyl = { pkgs, ... }: {
    home.packages = [ pkgs.tridactyl-native ];

    home.file.".mozilla/native-messaging-hosts/tridactyl.json" = {
      source = "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";
    };
  };
}
