{
  flake.nixosModules.session =
    {
      constants,
      lib,
      pkgs,
      ...
    }:
    {
      # No display manager: getty autologs in on tty1 and the login shell
      # execs startx there (see shell.nix). Other consoles get a plain
      # logged-in shell.
      services.getty.autologinUser = constants.username;

      services.fwupd.enable = true;
      security.rtkit.enable = true;
      services.printing.enable = true;

      hardware.bluetooth.enable = true;

      xdg.portal.enable = true;
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      # No desktop sets XDG_CURRENT_DESKTOP here, so name the backend
      # explicitly instead of relying on portal fallback order.
      xdg.portal.config.common.default = [ "gtk" ];

      # Provides the activatable ca.desrt.dconf user service. Load-bearing:
      # HM's dconfSettings activation hard-fails without it, aborting the
      # whole activation before any links land.
      programs.dconf.enable = true;

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
    };
}
