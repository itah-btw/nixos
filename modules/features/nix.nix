{ ... }:
{
  flake.modules.nixos.nix = { ... }: {
    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    environment.sessionVariables.XKB_LOG_LEVEL = "error";
    environment.variables = {
      EDITOR = "vis";
      VISUAL = "vis";
    };
    xdg.mime.defaultApplications = {
      "text/plain" = "vis.desktop";
    };
  };
}
