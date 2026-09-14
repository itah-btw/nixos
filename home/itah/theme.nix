{...}: let
  # Shared GTK settings (GTK3 and GTK4 both reference this).
  gtkConf = ''
    [Settings]
    gtk-theme-name=catppuccin-mocha
    gtk-icon-theme-name=Papirus-Dark
    gtk-cursor-theme-name=catppuccin-mocha-mauve-cursors
    gtk-font-name=JetBrainsMono Nerd Font 10
  '';
in {
  # Single fixed Catppuccin Mocha (mauve) theme, no switcher.

  # Cursor at the X level (Qt/Java/WebKit read this via xrdb).
  xdg.configFile."Xresources".text = ''
    Xcursor.theme: catppuccin-mocha-mauve-cursors
    Xcursor.size: 24
  '';

  # libXcursor fallback for non-GTK apps (per-user X cursor search dir is ~/.icons).
  home.file.".icons/default/index.theme".text = ''
    [Icon Theme]
    Inherits=catppuccin-mocha-mauve-cursors
  '';

  xdg.configFile."dunst/dunstrc".text = ''
    [global]
        monitor = 0
        follow = mouse
        width = (300, 400)
        height = (0, 120)
        offset = (12, 48)
        origin = top-right
        notification_limit = 5
        transparency = 0
        frame_width = 2
        frame_color = "#cba6f7"
        gap_size = 6
        padding = 12
        horizontal_padding = 12
        text_icon_padding = 6
        separator_color = frame
        font = JetBrainsMono Nerd Font 10
        line_height = 0
        format = "<b>%s</b>\n%b"
        markup = full
        vertical_alignment = center
        show_age_threshold = 60
        ellipsize = middle
        stack_duplicates = true
        hide_duplicate_count = true
        show_indicators = true
        progress_bar = true
        progress_bar_height = 12
        progress_bar_min_width = 150
        progress_bar_max_width = 300
        progress_bar_frame_width = 1
        icon_position = left
        min_icon_size = 32
        max_icon_size = 48
        enable_recursive_icon_lookup = true
        icon_theme = Papirus-Dark,Adwaita
        sticky_history = true
        history_length = 30
        dmenu = dmenu_run -p dunst
        browser = xdg-open
        mouse_left_click = close_current
        mouse_middle_click = do_action, remove_current
        mouse_right_click = close_all

    [urgency_low]
        background = "#1e1e2e"
        foreground = "#cdd6f4"
        frame_color = "#6c7086"
        timeout = 6

    [urgency_normal]
        background = "#1e1e2e"
        foreground = "#cdd6f4"
        highlight = "#cba6f7"
        timeout = 10

    [urgency_critical]
        background = "#1e1e2e"
        foreground = "#f38ba8"
        frame_color = "#f38ba8"
        highlight = "#f38ba8"
        timeout = 0
  '';

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

  xdg.configFile."gtk-3.0/settings.ini".text = gtkConf;
  xdg.configFile."gtk-4.0/settings.ini".text = gtkConf;

  # Terminal: Catppuccin Mocha (mauve accent), 6.5pt (~14px on 161 dpi).
  xdg.configFile."alacritty/alacritty.toml".text = ''
    [window]
    padding = { x = 0, y = 0 }
    dynamic_padding = false
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

  # glow markdown viewer: Catppuccin Mocha glamour style.
  xdg.configFile."glow/glow.yml".text = ''
    style: "/home/itah/.config/oxwm/glow-catppuccin.json"
    pager: false
    width: 80
  '';
}
