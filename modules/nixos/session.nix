{
  flake.nixosModules.session =
    {
      constants,
      lib,
      pkgs,
      ...
    }:
    {
      programs.umbriel.enable = true;

      programs.noctalia = {
        enable = true;
        recommendedServices.enable = true;
        systemd.enable = false;
      };

      services.displayManager.noctalia-greeter = {
        enable = true;
        passwordless-sync-users = [ constants.username ];
        cursorTheme.package = pkgs.bibata-cursors;
        settings = {
          cursor = {
            theme = constants.cursorTheme;
            size = constants.cursorSize;
          };
          keyboard.layout = constants.layout;
        };
      };

      services.fwupd.enable = true;
      security.rtkit.enable = true;
      services.printing.enable = true;

      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "corefonts"
          "intelephense"
          "vista-fonts"
          "vscode"
        ];

      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-color-emoji
        liberation_ttf
        inter
        corefonts
        vista-fonts
      ];
      fonts.fontconfig.defaultFonts = {
        sansSerif = [ constants.sansFont ];
        monospace = [ constants.monoFont ];
      };

      # Not a restatement: graphical-desktop.nix turns speechd on with
      # `mkDefault true` whenever a display manager is enabled.
      services.speechd.enable = false;

      services.gnome.gnome-keyring.enable = true;
      programs.seahorse.enable = true;
      services.fprintd.enable = true;
      security.pam.services.login.fprintAuth = false;
      security.pam.services.greetd.fprintAuth = false;
    };
}
