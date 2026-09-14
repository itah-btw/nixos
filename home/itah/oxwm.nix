{...}: {
  # oxwm reads ~/.config/oxwm/config.lua (reload with Mod+Shift+R).
  xdg.configFile."oxwm/config.lua".source = ./oxwm-config.lua;
  xdg.configFile."oxwm/glow-catppuccin.json".source = ./glow-catppuccin.json;
  xdg.configFile."oxwm/wallpaper.jpg".source = ./wallpaper.jpg;

  # CPU% for the topbar: diffs /proc/stat jiffies between ticks.
  xdg.configFile."oxwm/cpu.sh" = {
    executable = true;
    text = ''
      #!/run/current-system/sw/bin/bash
      state="$HOME/.cache/oxwm/cpu.state"
      mkdir -p "$(dirname "$state")"
      pt=0
      pi=0
      [[ -f $state ]] && IFS=' ' read -r pt pi < "$state" 2>/dev/null
      IFS=' ' read -r _ u n s idle iowait irq soft steal _g _gn < /proc/stat 2>/dev/null || { echo ERR; exit 0; }
      total=$((u + n + s + idle + iowait + irq + soft + steal))
      idlef=$((idle + iowait))
      printf '%s %s\n' "$total" "$idlef" > "$state"
      if (( pt > 0 )); then
        dt=$(( total - pt ))
        di=$(( idlef - pi ))
        if (( dt > 0 )); then
          echo $(( 100 - di * 100 / dt ))
        else
          echo 0
        fi
      else
        echo 0
      fi
    '';
  };

  # Mod+V "sync": re-timestamps the current clipboard to the top of clipmenu history,
  # then opens the picker (works around clipmenud's skip-identical-copies lag).
  xdg.configFile."oxwm/clipmenu-sync.sh" = {
    executable = true;
    text = ''
      #!/run/current-system/sw/bin/bash
      CM_DIR="''${CM_DIR:-$HOME/.cache/clipmenu}"
      export CM_DIR

      DMENU_ARGS="-nb #1e1e2e -nf #cdd6f4 -sb #cba6f7 -sf #1e1e2e"
      cache_dir="$CM_DIR/clipmenu.6.$USER"
      cache_file="$cache_dir/line_cache"

      data=$(xclip -selection clipboard -o 2>/dev/null || true)
      if [[ -z $data ]]; then
        exec clipmenu $DMENU_ARGS
      fi

      first_line=$(printf '%s' "$data" | awk -v limit=300 '
        BEGIN { printed = 0 }
        printed == 0 && NF {
          $0 = substr($0, 0, limit)
          printf("%s", $0)
          printed = 1
        }
        END { if (NR > 1) printf(" (%d lines)", NR); printf("\n") }')

      mkdir -p "$cache_dir"
      printf '%s %s\n' "$(date +%s%N)" "$first_line" >> "$cache_file"
      printf '%s' "$data" > "$cache_dir/$(cksum <<< "$first_line")"

      exec clipmenu $DMENU_ARGS
    '';
  };
}
