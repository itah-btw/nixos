# Brightness stepping for umbriel.nix's XF86MonBrightness* chords. Reads sysfs
# itself because Noctalia's fixed 5% step makes the bottom of the range unreachable.
{
  flake.homeManagerModules.brightness = { pkgs, ... }: {
    home.packages = [
      (pkgs.writeShellScriptBin "brightness-step" ''
        pct=""
        for dev in /sys/class/backlight/*; do
          if [ -r "$dev/brightness" ] && [ -r "$dev/max_brightness" ]; then
            pct=$(( 100 * $(cat "$dev/brightness") / $(cat "$dev/max_brightness") ))
            break
          fi
        done
        if [ "$1" = "up" ]; then
          [ -n "$pct" ] || exec noctalia msg brightness-up
          if [ "$pct" -lt 5 ]; then target=$(( pct + 1 )); else target=$(( pct + 5 )); fi
        else
          [ -n "$pct" ] || exec noctalia msg brightness-down
          if [ "$pct" -le 5 ]; then target=$(( pct - 1 )); else target=5; fi
          [ "$target" -lt 1 ] && target=1
        fi
        noctalia msg brightness-set "$target"
      '')
    ];
  };
}
