{...}: {
  imports = [
    ./bash.nix
    ./cli.nix
    ./nvim.nix
    ./yazi.nix
    ./mime.nix
    ./oxwm.nix
    ./theme.nix
  ];

  home.username = "itah";
  home.homeDirectory = "/home/itah";
  home.stateVersion = "26.11";

  programs.home-manager.enable = true;

  home.sessionVariables = {
    BROWSER = "brave-origin";
    EDITOR = "nvim";
    TERMINAL = "alacritty";
    VISUAL = "nvim";
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    extraConfig.XDG_SCREENSHOTS_DIR = "$HOME/Pictures/Screenshots";
  };
}
