{
  config,
  pkgs,
  ...
}: {
  home.username = "itah";
  home.homeDirectory = "/home/itah";
  home.stateVersion = "26.11";

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    shellAliases = {
      update = "sudo nix flake update /etc/nixos";
      upgrade = "sudo systemctl start nixos-upgrade.service";
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      rebt = "sudo nixos-rebuild test --flake /etc/nixos#nixos";
      drv = "sudo nixos-rebuild dry-run --flake /etc/nixos#nixos";
      gc = "sudo nix-collect-garbage --delete-older-than 7d";
      gcr = "sudo nix-collect-garbage -d";
      gens = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      rollback = "sudo nixos-rebuild switch --rollback";
      npush = "nixsync";
      npull = "sudo git -C /etc/nixos pull";
    };
    bashrcExtra = ''
      # Commit + push the /etc/nixos config (auto-run after rebuild/update/rebt,
      # or manually with `npush`). /etc/nixos is root-owned, so git runs via sudo
      # (root's SSH key authenticates to GitHub).
      nixsync() {
        local g="/etc/nixos" msg
        msg="sync: $(date '+%F %T')"
        [ -n "$1" ] && msg="$1"
        sudo git -C "$g" add -A || return 1
        if sudo git -C "$g" diff --cached --quiet; then
          echo "nothing to commit"
          return 0
        fi
        sudo git -C "$g" commit -m "$msg" && sudo git -C "$g" push
      }
    '';
    profileExtra = ''
      # No display manager: auto-start oxwm via startx on tty1 after getty autologin.
      # Clipmenu history lives on /home so it survives reboots; export CM_DIR so
      # both the client (dmenu picker) and the daemon read the same file.
      export CM_DIR="$HOME/.cache/clipmenu"
      # oxwm is a non-reparenting WM: Java/Swing apps (e.g. NetBeans) need
      # this hint or they render a blank window.
      export _JAVA_AWT_WM_NONREPARENTING=1
      # Cursor theme: libXcursor reads XCURSOR_THEME before anything else, so
      # this covers every toolkit (GTK/Qt/Java/WebKit), not just settings.ini.
      export XCURSOR_THEME=catppuccin-mocha-mauve-cursors
      export XCURSOR_SIZE=24
      if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
        exec startx
      fi
    '';
  };

  home.packages = with pkgs; [
  ];

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    # Archive pack/unpack via ouch (browse into archives with Enter/l).
    keymap.mgr.prepend_keymap = [
      {
        on = ["c" "a"];
        run = "shell 'ouch compress %s archive.zip' --confirm";
        desc = "Compress selected files to archive.zip";
      }
      {
        on = ["c" "x"];
        run = "shell 'for a in %s; do ouch decompress \"$a\" --yes; done' --confirm";
        desc = "Extract selected archives here";
      }
    ];
  };

  home.sessionVariables = {
    BROWSER = "brave-origin";
    EDITOR = "nvim";
    TERMINAL = "alacritty";
    VISUAL = "nvim";
  };

  # Full keybind cheatsheet (shown by Mod+Shift+/ via glow); keep in sync with oxwm-config.lua.
  xdg.configFile."oxwm/keybinds.md".text = ''
    # OXWM Keybinds

    `Mod` = Super (Mod4). Press `Mod+Shift+/` anytime to reopen this.

    ## Windows

    | Keys                   | Action              |
    | ---------------------- | ------------------- |
    | `Mod+Return`           | Terminal            |
    | `Mod+D`                | Dmenu launcher      |
    | `Mod+Q`                | Close window        |
    | `Mod+Shift+Q`          | Quit oxwm           |
    | `Mod+Shift+R`          | Reload config       |
    | `Mod+Shift+Slash`      | This cheatsheet     |
    | `Mod+Shift+F`          | Toggle fullscreen   |
    | `Mod+Shift+Space`      | Toggle floating     |
    | `Mod+A`                | Toggle gaps         |
    | `Mod+B`                | Toggle bar          |

    ## Layout & Focus

    | Keys                      | Action                    |
    | ------------------------- | ------------------------- |
    | `Mod+F`                   | Layout: normie            |
    | `Mod+C`                   | Layout: tiling            |
    | `Mod+N`                   | Cycle layouts             |
    | `Mod+J` / `Mod+K`         | Focus next / prev         |
    | `Mod+Shift+J` / `K`       | Move window in stack      |
    | `Mod+H` / `Mod+L`         | Master area - / + 5%      |
    | `Mod+I` / `Mod+P`         | - / + number of masters   |
    | `Mod+Comma` / `Mod+.`     | Focus prev / next monitor |
    | `Mod+Shift+Comma` / `.`   | Move window to monitor    |
    | `Mod+1..9`                | View tag                  |
    | `Mod+Shift+1..9`          | Move window to tag        |
    | `Mod+Ctrl+1..9`           | Toggle view of tags       |
    | `Mod+Ctrl+Shift+1..9`     | Toggle window tags        |

    ## App Launchers

    | Keys             | Action                |
    | ---------------- | --------------------- |
    | `Mod+Shift+O`    | opencode (TUI)        |
    | `Mod+Shift+Y`    | yazi (TUI)            |
    | `Mod+Shift+B`    | btop (TUI)            |
    | `Mod+T`          | Thunar                |
    | `Mod+W`          | Brave                 |
    | `Mod+Shift+L`    | LibreOffice           |
    | `Mod+Shift+M`    | LocalSend             |
    | `Mod+Shift+P`    | OBS Studio            |
    | `Mod+E`          | fastfetch (floating)  |
    | `Mod+Shift+N`    | nmtui (floating)      |
    | `Mod+Shift+T`    | bluetui (floating)    |
    | `Mod+Shift+C`    | calcurse (floating)   |

    ## Screen & Clipboard

    | Keys    | Action                           |
    | ------- | -------------------------------- |
    | `Mod+S` | Screenshot selection to clipboard |
    | `Mod+O` | OCR selection to clipboard        |
    | `Mod+V` | Clipboard history (clipmenu)      |

    ## Media / OSD

    | Keys                  | Action                    |
    | --------------------- | ------------------------- |
    | `BrightnessUp/Down`   | Brightness ±5% (OSD)      |
    | `AudioRaise/Lower`    | Volume ±5% (OSD)          |
    | `AudioMute`           | Mute / unmute (OSD)       |
  '';

  # File associations: opening files goes to the right apps.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "thunar.desktop";

      "application/pdf" = "org.pwmt.zathura-pdf-mupdf.desktop";

      "image/png" = "imv-dir.desktop";
      "image/jpeg" = "imv-dir.desktop";
      "image/gif" = "imv-dir.desktop";
      "image/webp" = "imv-dir.desktop";
      "image/bmp" = "imv-dir.desktop";
      "image/tiff" = "imv-dir.desktop";
      # imv has no SVG support; browsers render it perfectly.
      "image/svg+xml" = "brave-origin.desktop";

      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "video/mpeg" = "mpv.desktop";
      "video/ogg" = "mpv.desktop";
      "video/x-msvideo" = "mpv.desktop";
      "video/x-flv" = "mpv.desktop";
      "audio/mpeg" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/wav" = "mpv.desktop";
      "audio/x-wav" = "mpv.desktop";
      "audio/mp4" = "mpv.desktop";
      "audio/webm" = "mpv.desktop";

      "text/plain" = "nvim.desktop";
      "text/markdown" = "nvim.desktop";
      "application/json" = "nvim.desktop";
      "application/xml" = "nvim.desktop";
      "text/css" = "nvim.desktop";
      "application/javascript" = "nvim.desktop";
      "text/x-csrc" = "nvim.desktop";
      "text/x-chdr" = "nvim.desktop";
      "text/x-python" = "nvim.desktop";
      "application/x-shellscript" = "nvim.desktop";

      "text/html" = "brave-origin.desktop";
      "application/xhtml+xml" = "brave-origin.desktop";
      "x-scheme-handler/http" = "brave-origin.desktop";
      "x-scheme-handler/https" = "brave-origin.desktop";
      "x-scheme-handler/about" = "brave-origin.desktop";
      "x-scheme-handler/unknown" = "brave-origin.desktop";

      "application/msword" = "writer.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop";
      "application/vnd.oasis.opendocument.text" = "writer.desktop";
      "application/vnd.ms-excel" = "calc.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "calc.desktop";
      "application/vnd.oasis.opendocument.spreadsheet" = "calc.desktop";
      "text/csv" = "calc.desktop";
      "application/vnd.ms-powerpoint" = "impress.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "impress.desktop";
      "application/vnd.oasis.opendocument.presentation" = "impress.desktop";
      "application/vnd.oasis.opendocument.graphics" = "draw.desktop";
    };
  };

  # oxwm reads ~/.config/oxwm/config.lua (reload with Mod+Shift+R).
  xdg.configFile."oxwm/config.lua".source = ./oxwm-config.lua;

  # CPU% for the topbar: diffs /proc/stat jiffies between ticks. Always
  # prints one line (0/percent/ERR) so the bar never goes blank.
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

  # Mod+V "sync": clipmenud skips re-copying identical text, so the picker's top
  # entry can lag what's actually in your clipboard. This wrapper re-timestamps
  # the current clipboard to the top of history (same naming/layout clipmenud
  # uses — display dedupe then keeps the newest copy), then opens the picker.
  xdg.configFile."oxwm/clipmenu-sync.sh" = {
    executable = true;
    text = ''
            #!/run/current-system/sw/bin/bash
      CM_DIR="''${CM_DIR:-$HOME/.cache/clipmenu}"
            export CM_DIR

            # Theme the dmenu picker to Catppuccin Mocha (mauve).
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

  # Cursor theme at the X level (Qt/Java/WebKit apps read this via xrdb).
  xdg.configFile."Xresources".text = ''
    Xcursor.theme: catppuccin-mocha-mauve-cursors
    Xcursor.size: 24
  '';

  # Fallback for non-GTK apps: points libXcursor to the Catppuccin cursor.
  # ~/.icons (not ~/.config/icons) is the per-user X cursor search dir.
  home.file.".icons/default/index.theme".text = ''
    [Icon Theme]
    Inherits=catppuccin-mocha-mauve-cursors
  '';

  # Notification popups (dunst), Catppuccin Mocha colors (mauve accent).
  xdg.configFile."dunst/dunstrc".text = ''
    [global]
        width = 320
        height = (0, 120)
        offset = (12, 48)
        origin = top-right
        font = JetBrainsMono Nerd Font 10
        frame_width = 2
        frame_color = "#cba6f7"
        transparency = 0

    [urgency_low]
        background = "#1e1e2e"
        foreground = "#cdd6f4"
        timeout = 6

    [urgency_normal]
        background = "#1e1e2e"
        foreground = "#cdd6f4"
        timeout = 10

    [urgency_critical]
        background = "#f38ba8"
        foreground = "#1e1e2e"
        timeout = 0
  '';

  # btop (single fixed theme; btop reads this config at launch). The
  # Catppuccin Mocha theme file lives in themes/ below.
  xdg.configFile."btop/btop.conf".text = ''
    color_theme = "catppuccin_mocha"
    theme_background = false
  '';

  xdg.configFile."btop/themes/catppuccin_mocha.theme".text = ''
    theme[main_bg] = "#1e1e2e"
    theme[main_fg] = "#cdd6f4"

    theme[title] = "#cba6f7"
    theme[hi_fg] = "#cba6f7"
    theme[selected_bg] = "#45475a"
    theme[selected_fg] = "#cdd6f4"

    theme[inactive_fg] = "#6c7086"
    theme[proc_misc] = "#6c7086"
    theme[cpu_box] = "#89b4fa"
    theme[mem_box] = "#a6e3a1"
    theme[net_box] = "#f9e2af"
    theme[proc_box] = "#f38ba8"

    theme[div_line] = "#45475a"

    theme[temp_start] = "#f9e2af"
    theme[temp_mid] = "#fab387"
    theme[temp_end] = "#f38ba8"

    theme[cpu_start] = "#89b4fa"
    theme[cpu_mid] = "#cba6f7"
    theme[cpu_end] = "#f38ba8"

    theme[free_start] = "#313244"
    theme[free_mid] = "#45475a"
    theme[free_end] = "#585b70"

    theme[cached_start] = "#313244"
    theme[cached_mid] = "#45475a"
    theme[cached_end] = "#585b70"

    theme[available_start] = "#313244"
    theme[available_mid] = "#45475a"
    theme[available_end] = "#585b70"

    theme[used_start] = "#a6e3a1"
    theme[used_mid] = "#cba6f7"
    theme[used_end] = "#f38ba8"

    theme[download_start] = "#89b4fa"
    theme[download_mid] = "#cba6f7"
    theme[download_end] = "#f38ba8"

    theme[upload_start] = "#cba6f7"
    theme[upload_mid] = "#f5c2e7"
    theme[upload_end] = "#f38ba8"

    theme[proc_start] = "#cba6f7"
    theme[proc_mid] = "#89b4fa"
    theme[proc_end] = "#f38ba8"

    theme[debug_start] = "#f9e2af"
    theme[debug_mid] = "#f9e2af"
    theme[debug_end] = "#f38ba8"
  '';

  # GTK apps (Thunar, etc.): single fixed Catppuccin Mocha (mauve) theme.
  # Icons are Papirus-Dark, cursor Catppuccin Mocha Mauve. Plain
  # settings.ini (not the gtk module) to avoid dconf/bus activation.
  xdg.configFile."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=catppuccin-mocha
    gtk-icon-theme-name=Papirus-Dark
    gtk-cursor-theme-name=catppuccin-mocha-mauve-cursors
    gtk-font-name=JetBrainsMono Nerd Font 10
  '';

  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=catppuccin-mocha
    gtk-icon-theme-name=Papirus-Dark
    gtk-cursor-theme-name=catppuccin-mocha-mauve-cursors
    gtk-font-name=JetBrainsMono Nerd Font 10
  '';

  # Terminal (alacritty), Catppuccin Mocha colors baked in (mauve accent).
  # Font note: this panel is 161 dpi, so alacritty renders `size * dpi/72` px
  # (factor 2.22); 6.5pt ~= 14px. Bump ~0.5pt per pixel of growth.
  xdg.configFile."alacritty/alacritty.toml".text = ''
    [window]
    padding = { x = 6, y = 6 }
    dynamic_padding = true
    # Fully opaque window: with a compositor absent, an ARGB window (opacity<1)
    # has no one to blend it, and oxwm's solid border needs an opaque window.
    opacity = 1.0

    [font]
    size = 6.5
    normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
    bold = { family = "JetBrainsMono Nerd Font", style = "Bold" }
    italic = { family = "JetBrainsMono Nerd Font", style = "Italic" }
    bold_italic = { family = "JetBrainsMono Nerd Font", style = "Bold Italic" }

    [cursor]
    style = { shape = "Block", blinking = "On" }

    [colors]
    primary = { background = "#1e1e2e", foreground = "#cdd6f4" }

    normal = { black = "#45475a", red = "#f38ba8", green = "#a6e3a1", yellow = "#f9e2af", blue = "#89b4fa", magenta = "#f5c2e7", cyan = "#94e2d5", white = "#bac2de" }
    bright = { black = "#585b70", red = "#f38ba8", green = "#a6e3a1", yellow = "#f9e2af", blue = "#89b4fa", magenta = "#f5c2e7", cyan = "#94e2d5", white = "#a6adc8" }

    selection = { text = "#cdd6f4", background = "#313244" }
  '';

  # Standard folders: Documents, Downloads, Music, Pictures, Videos, ...

  # Standard folders: Documents, Downloads, Music, Pictures, Videos, ...
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    extraConfig.XDG_SCREENSHOTS_DIR = "$HOME/Pictures/Screenshots";
  };
}
