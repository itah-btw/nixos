# OCR: region-select, recognise, copy. Bound to Mod+Shift+O in umbriel.nix.
{
  flake.homeManagerModules.ocr = { pkgs, ... }: {
    home.packages = [
      (pkgs.writeShellScriptBin "ocr-copy" ''
        tmp=$(mktemp --suffix .png)
        trap 'rm -f "$tmp"' EXIT
        grim -g "$(slurp)" "$tmp" || exit 1
        # Capture before copying: a failed run piped to wl-copy would clear it.
        text=$(tesseract "$tmp" - -l eng+ind 2>/dev/null) || {
          echo "ocr-copy: tesseract failed; clipboard untouched" >&2
          exit 1
        }
        if [ -z "$text" ]; then
          echo "ocr-copy: no text recognised; clipboard untouched" >&2
          exit 1
        fi
        printf '%s' "$text" | wl-copy
      '')

      # wl-copy comes from cli-tools.nix; grim and slurp are only used here.
      pkgs.grim
      pkgs.slurp
      # nixpkgs ships eng only.
      (pkgs.tesseract.override {
        enableLanguages = [
          "eng"
          "ind"
        ];
      })
    ];
  };
}
