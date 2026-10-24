{ ... }:
{
  flake.modules.nixos.nix = { ... }: {
    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Silence harmless libxkbcommon warnings (duplicate virtual modifiers,
    # unsupported keycodes, unresolvable keysyms) emitted by Umbriel/Noctalia.
    environment.sessionVariables.XKB_LOG_LEVEL = "error";
  };
}
