# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Jakarta";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."itah" = {
    isNormalUser = true;
    description = "itah";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable the nix3 CLI and flakes.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Home Manager, managed through the NixOS module so everything
  # is applied by `nixos-rebuild switch` in a single transaction.
  home-manager.users.itah = {
    home.stateVersion = "26.11";
    home.packages = with pkgs; [
      # Add per-user (non-system) packages here.
    ];

    # Declarative Umbriel config: ~/.config/umbriel/config.toml becomes a
    # read-only symlink into the Nix store, so edits go through git + rebuild.
    xdg.configFile."umbriel/config.toml".source = ./umbriel/config.toml;
  };

  # ── Desktop: Umbriel compositor + Noctalia shell ──────────────────────
  # Umbriel: Wayland compositor (wlroots + SceneFX) built by the Noctalia
  # project. The module registers the session, sets up the portal for
  # screen sharing, and pulls in the graphics bits.
  programs.umbriel.enable = true;

  # `programs.umbriel` also pulls in xdg-desktop-portal-gtk as a fallback for
  # the interfaces Umbriel does not implement (FileChooser, Settings,
  # Notification, ...). That fallback costs ~920 MiB (gtk4, gnome-desktop,
  # gst-plugins-bad) and nothing here uses it, so force the portal list down
  # to just Umbriel's backend. Re-add `pkgs.xdg-desktop-portal-gtk` if you
  # start using Flatpak apps (they need the FileChooser portal).
  xdg.portal.extraPortals = lib.mkForce [ pkgs.xdg-desktop-portal-umbriel ];

  programs.noctalia = {
    enable = true;
    # Autostart the shell inside Umbriel's session target.
    systemd.enable = true;
    systemd.target = "umbriel-session.target";
    # NetworkManager, bluetooth, UPower, power-profiles-daemon.
    recommendedServices.enable = true;
  };

  # Login screen (greetd-based Wayland greeter).
  services.displayManager.noctalia-greeter = {
    enable = true;
    settings = {
      cursor = {
        theme = "Adwaita";
        size = 24;
      };
      keyboard.layout = "us";
    };
  };

  # Audio, for the shell's volume keys and media controls.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    git
    kitty # Umbriel's default Mod+Return binding spawns kitty
    vis # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    opencode
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.11"; # Did you read the comment?

}
