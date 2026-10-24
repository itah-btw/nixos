{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Jakarta";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  users.users."itah" = {
    isNormalUser = true;
    description = "itah";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  home-manager.users.itah = {
    home.stateVersion = "26.11";
    home.packages = with pkgs; [];
    xdg.configFile."umbriel/config.toml".source = ./umbriel/config.toml;
  };

  programs.umbriel.enable = true;

  xdg.portal.extraPortals = lib.mkForce [ pkgs.xdg-desktop-portal-umbriel ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    systemd.target = "graphical-session.target";
    recommendedServices.enable = true;
  };

  services.displayManager.noctalia-greeter = {
    enable = true;
    settings = {
      cursor = { theme = "Adwaita"; size = 24; };
      keyboard.layout = "us";
    };
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.speechd.enable = false;

  environment.systemPackages = with pkgs; [
    git
    kitty
    vis
    wget
    opencode
  ];

  system.stateVersion = "26.11";
}
