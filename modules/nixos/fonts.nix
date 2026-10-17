{
  flake.nixosModules.fonts =
    {
      constants,
      pkgs,
      ...
    }:
    {
      fonts.packages = with pkgs; [
        corefonts
        inter
        liberation_ttf
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-color-emoji
        vista-fonts
      ];
      fonts.fontconfig.defaultFonts = {
        sansSerif = [ constants.sansFont ];
        monospace = [ constants.monoFont ];
      };
    };
}
