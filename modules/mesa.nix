{
  # mesa 26.2.3 built by nixpkgs 7a0f122 initialises EGL for noctalia; the
  # b4fd65b1 rebuild of the *same version* returns EGL_NO_DISPLAY and the shell
  # dies at startup (nixpkgs#553285 is a different 26.2 regression, same series).
  # Pinned here so `nsu` can float nixpkgs without breaking the desktop.
  flake.nixosModules.mesa = { inputs, pkgs, ... }: {
    hardware.graphics.package =
      inputs.mesa-pinned.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mesa;
  };
}
