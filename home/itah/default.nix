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
      export XCURSOR_THEME=Bibata-Modern-Classic
      export XCURSOR_SIZE=24
      # Generate runtime theme files (oxwm/alacritty/dunst/wallpaper) on login
      # if they don't exist yet, so `theme apply` and dunst -config always work.
      theme ensure >/dev/null 2>&1 || true
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

            # Theme the dmenu picker to match the current desktop theme (flags are
            # written by `theme apply`/`theme ensure`).
            DMENU_ARGS=""
            if [[ -f "$HOME/.config/oxwm/theme-current.env" ]]; then
              source "$HOME/.config/oxwm/theme-current.env"
              DMENU_ARGS="-nb $DMENU_NB -nf $DMENU_NF -sb $DMENU_SB -sf $DMENU_SF"
            fi
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

  # GTK apps (Thunar, etc.): theme is owned by the `theme` tool, which writes
  # ~/.config/gtk-{3,4}.0/settings.ini at login (`theme ensure`) and on every
  # `theme apply`. Icons stay on Qogir, cursor stays Bibata for all themes.
  # Plain settings.ini (not the gtk module) to avoid dconf/bus activation.

  # Cursor theme at the X level (Qt/Java/WebKit apps read this via xrdb).
  xdg.configFile."Xresources".text = ''
    Xcursor.theme: Bibata-Modern-Classic
    Xcursor.size: 24
  '';

  # Fallback for non-GTK apps: points libXcursor to the Bibata theme.
  xdg.configFile."icons/default/index.theme".text = ''
    [Icon Theme]
    Inherits=Bibata-Modern-Classic
  '';

  # Notification popups (dunst), colors matched to the topbar palette.
  xdg.configFile."dunst/dunstrc".text = ''
    [global]
        width = 320
        height = (0, 120)
        offset = (12, 48)
        origin = top-right
        font = JetBrainsMono Nerd Font 10
        frame_width = 2
        frame_color = "#6dade3"
        transparency = 20

    [urgency_low]
        background = "#1f2335"
        foreground = "#c0caf5"
        timeout = 6

    [urgency_normal]
        background = "#1f2335"
        foreground = "#c0caf5"
        timeout = 10

    [urgency_critical]
        background = "#f7768e"
        foreground = "#1f2335"
        timeout = 0
  '';

  # Terminal (alacritty). Base options; colors live in theme-current.toml
  # (written by `theme`), which is imported here so `theme apply` works live.
  # Font note: this panel is 161 dpi, so alacritty renders `size * dpi/72` px
  # (factor 2.22); 6.5pt ~= 14px. Bump ~0.5pt per pixel of growth.
  xdg.configFile."alacritty/alacritty.toml".text = ''
    general.import = ["/home/itah/.config/alacritty/theme-current.toml"]

    [window]
    padding = { x = 6, y = 6 }
    dynamic_padding = true
    # Fully opaque: any opacity<1 makes alacritty an ARGB window and picom
    # renders the oxwm border around it semi-transparent (see-through focus
    # border). 1.0 keeps the border solid.
    opacity = 1.0

    [font]
    size = 6.5
    normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
    bold = { family = "JetBrainsMono Nerd Font", style = "Bold" }
    italic = { family = "JetBrainsMono Nerd Font", style = "Italic" }
    bold_italic = { family = "JetBrainsMono Nerd Font", style = "Bold Italic" }

    [cursor]
    style = { shape = "Block", blinking = "On" }
  '';

  # Compositor with GLX VSync (started from oxwm autostart).
  xdg.configFile."picom/picom.conf".text = ''
    backend = "glx";
    vsync = true;

    # Let fullscreen apps own the screen instead of being re-composited.
    unredir-if-possible = true;
    detect-rounded-corners = true;

    shadow = false;
    fading = false;
  '';

  # Standard folders: Documents, Downloads, Music, Pictures, Videos, ...
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    extraConfig.XDG_SCREENSHOTS_DIR = "$HOME/Pictures/Screenshots";
  };
}
