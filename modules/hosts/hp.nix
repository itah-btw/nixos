# hp: Umbriel + Noctalia laptop; the other composition point is tv.nix.
{
  inputs,
  config,
  mkHost,
  ...
}:
let
  # Sorted so adding a module is a one-line diff. Order does change the store
  # hash (see the nixos skill) but not what the system is.
  wiring = {
    nixos = [
      "boot"
      "fingerprint"
      "hp-packages"
      "keyring"
      "locale"
      "mariadb"
      "networking"
      "nix"
      "nixpkgs"
      "performance"
      "session"
      "shared-packages"
      "shell"
      "user"
    ];
    home = [
      "aliases"
      "android"
      "apps"
      "base"
      "brightness"
      "c-toolchain"
      "cli-tools"
      "cursor"
      "identity"
      "mariadb"
      "neovim"
      "noctalia"
      "ocr"
      "shell"
      "tridactyl"
      "umbriel"
      "yazi"
    ];
  };
in
{
  flake.hostModules.hp = wiring;

  flake.nixosConfigurations.hp = mkHost {
    inherit inputs config;
    name = "hp";
    inherit wiring;
    stateVersion = "26.11";
    hardware = ../../hardware-configuration.nix;

    nixosImports = [
      inputs.umbriel.nixosModules.default
      inputs.noctalia.nixosModules.default
      inputs.noctalia-greeter.nixosModules.default
    ];
    hmImports = [
      inputs.noctalia.homeModules.default
      inputs.umbriel.homeModules.default
    ];

    extra = {
      # LocalSend (53317) and KDE Connect (1714-1764), plus avahi's own
      # discovery port, scoped to the wifi NIC: a global port leaks discovery
      # onto any network joined.
      networking.firewall.interfaces."wlan0" = {
        allowedTCPPorts = [ 53317 ];
        # UDP 5353 is avahi's mDNS, the rule openFirewall used to add
        # globally; upstream opens the UDP port only.
        allowedUDPPorts = [
          5353
          53317
        ];
        allowedTCPPortRanges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
        allowedUDPPortRanges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
      };
    };
  };
}
