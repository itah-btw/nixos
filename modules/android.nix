# Android debugging and OTA image extraction.
{
  flake.homeManagerModules.android = { pkgs, ... }: {
    home.packages = with pkgs; [
      # The device's udev uaccess rules come with the package.
      android-tools
      # Payload bins from update / factory images.
      payload-dumper-go
    ];
  };
}
