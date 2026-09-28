# tv: Plasma Big Screen appliance; the other composition point is hp.nix.
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
      "locale"
      "networking"
      "nix"
      "nixpkgs"
      "shared-packages"
      "tv-bigscreen"
      "tv-display"
      "tv-hdd"
      "tv-openssh"
      "tv-packages"
      "tv-power"
      "user"
    ];
    home = [
      "identity"
      "tv-home"
    ];
  };
in
{
  flake.hostModules.tv = wiring;

  flake.nixosConfigurations.tv = mkHost {
    inherit inputs config;
    name = "tv";
    inherit wiring;
    stateVersion = "26.11";
    hardware = ../../hardware-configuration-tv.nix;

    hmImports = [ inputs.plasma-manager.homeModules.plasma-manager ];

    extra = {
      # Only for reaching an older generation. Not 0: no rescue entry beats
      # two seconds of black.
      boot.loader.timeout = 2;

      # avahi mDNS on the wired NIC only, in place of openFirewall: a fixed
      # appliance has no roaming interface, but this keeps the discovery
      # surface identical to the laptops'.
      networking.firewall.interfaces."enp2s0".allowedUDPPorts = [ 5353 ];
    };
  };
}
