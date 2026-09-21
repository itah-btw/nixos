# System-wide packages.
{ ... }:
{
  flake.nixosModules.system-packages = { pkgs, ... }: {
    # List packages installed in system profile.
    # You can use https://search.nixos.org/ to find more packages (and options).
    environment.systemPackages = with pkgs; [
      wget
      python3
      git
      opencode
      # No system neovim: nvf already provides nvim as EDITOR (see home/nvf.nix).
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
  };
}
