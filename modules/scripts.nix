{
  flake.homeManagerModules.scripts = { pkgs, ... }: {
    home.packages = [
      (pkgs.writeShellScriptBin "brightness-step" ''
        pct=""
        for dev in /sys/class/backlight/*; do
          if [ -r "$dev/brightness" ] && [ -r "$dev/max_brightness" ]; then
            read -r cur < "$dev/brightness"
            read -r max < "$dev/max_brightness"
            # Integer percent; max is never 0 on a real backlight.
            if [ "$max" -gt 0 ] 2>/dev/null; then
              pct=$(( 100 * cur / max ))
              break
            fi
          fi
        done
        if [ "$1" = "up" ]; then
          [ -n "$pct" ] || exec noctalia msg brightness-up
          if [ "$pct" -lt 5 ]; then target=$(( pct + 1 )); else target=$(( pct + 5 )); fi
        else
          [ -n "$pct" ] || exec noctalia msg brightness-down
          if [ "$pct" -le 5 ]; then target=$(( pct - 1 )); else target=$(( pct - 5 )); fi
          [ "$target" -lt 1 ] && target=1
        fi
        noctalia msg brightness-set "$target"
      '')
      (pkgs.writeShellScriptBin "ocr-copy" ''
        tmp=$(mktemp --suffix .png)
        trap 'rm -f "$tmp"' EXIT
        grim -g "$(slurp)" "$tmp" || exit 1
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
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard
      (pkgs.tesseract.override {
        enableLanguages = [
          "eng"
          "ind"
        ];
      })
    ];
  };
}
