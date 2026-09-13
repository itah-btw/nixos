#!/run/current-system/sw/bin/bash
# theme - desktop theme switcher (oxwm bar, borders, dmenu, alacritty, dunst,
# GTK themes, wallpaper). Run as the desktop user.
# Usage: theme apply <tokyonight|catppuccin|gruvbox> | theme list | theme current | theme ensure
exec /run/current-system/sw/bin/python3 - "$@" <<'PYEOF'
import os
import subprocess
import sys

HOME = os.path.expanduser("~")
THEME_DIR = HOME + "/.config/oxwm/themes"
OXWM_FILE = HOME + "/.config/oxwm/theme-current.lua"
DMENU_ENV = HOME + "/.config/oxwm/theme-current.env"
ALAC_FILE = HOME + "/.config/alacritty/theme-current.toml"
DUNST_FILE = HOME + "/.config/dunst/dunstrc.theme"
GTK3_FILE = HOME + "/.config/gtk-3.0/settings.ini"
GTK4_FILE = HOME + "/.config/gtk-4.0/settings.ini"
BTOP_CONF = HOME + "/.config/btop/btop.conf"
ACTIVE_FILE = HOME + "/.config/oxwm/theme.current"
WALL_CURRENT = THEME_DIR + "/current.jpg"

# Palette per theme. `colors` feeds oxwm's status bar blocks, separators, and
# tag schemes (normal/occupied/selected/urgent); border/dmenu feed the UI
# chrome; gtk feeds GTK theme lookup.
THEMES = {
    "tokyonight": {
        "colors": {
            "fg": "#c0caf5", "bg": "#1f2335", "red": "#f7768e",
            "cyan": "#7dcfff", "green": "#9ece6a", "lavender": "#3b4261",
            "light_blue": "#7aa2f7", "grey": "#3b4261", "blue": "#6dade3",
            "purple": "#bb9af7", "yellow": "#e0af68", "orange": "#ff9e64",
            "teal": "#73daca",
        },
        "border": ("#7aa2f7", "#3b4261"),
        "dmenu": ("#1f2335", "#c0caf5", "#7aa2f7", "#1f2335"),
        "gtk": ("Qogir-Dark", "Qogir"),
        "dmenu": ("#1f2335", "#c0caf5", "#7aa2f7", "#1f2335"),
        "gtk": ("Qogir-Dark", "Qogir"),
        "btop": "tokyo-night",
        "alacritty": {
            "bg": "#1f2335", "fg": "#c0caf5",
            "black": "#414868", "red": "#f7768e", "green": "#9ece6a",
            "yellow": "#e0af68", "blue": "#7aa2f7", "magenta": "#bb9af7",
            "cyan": "#7dcfff", "white": "#a9b1d6",
            "black_b": "#414868", "red_b": "#ff7a93", "green_b": "#b9f27c",
            "yellow_b": "#ff9e64", "blue_b": "#7aa2f7", "magenta_b": "#bb9af7",
            "cyan_b": "#7dcfff", "white_b": "#c0caf5",
        },
        "dunst": {
            "frame": "#7aa2f7", "low_bg": "#1f2335", "low_fg": "#c0caf5",
            "norm_bg": "#1f2335", "norm_fg": "#c0caf5",
            "crit_bg": "#f7768e", "crit_fg": "#1f2335",
        },
        "wall": HOME + "/Downloads/__koseki_bijou_hololive_and_1_more_drawn_by_advarcher__52162c28aa3ab6d87bb9998d48b93799.jpg",
    },
    "catppuccin": {
        "colors": {
            "fg": "#cdd6f4", "bg": "#1e1e2e", "red": "#f38ba8",
            "cyan": "#94e2d5", "green": "#a6e3a1", "lavender": "#45475a",
            "light_blue": "#89b4fa", "grey": "#45475a", "blue": "#89b4fa",
            "purple": "#cba6f7", "yellow": "#f9e2af", "orange": "#fab387",
            "teal": "#94e2d5",
        },
        "border": ("#89b4fa", "#45475a"),
        "dmenu": ("#1e1e2e", "#cdd6f4", "#89b4fa", "#1e1e2e"),
        "gtk": ("catppuccin-mocha-blue-standard+default", "Papirus-Dark"),
        "btop": "catppuccin_macchiato",
        "alacritty": {
            "bg": "#1e1e2e", "fg": "#cdd6f4",
            "black": "#45475a", "red": "#f38ba8", "green": "#a6e3a1",
            "yellow": "#f9e2af", "blue": "#89b4fa", "magenta": "#cba6f7",
            "cyan": "#94e2d5", "white": "#bac2de",
            "black_b": "#585b70", "red_b": "#f38ba8", "green_b": "#a6e3a1",
            "yellow_b": "#f9e2af", "blue_b": "#89b4fa", "magenta_b": "#cba6f7",
            "cyan_b": "#94e2d5", "white_b": "#cdd6f4",
        },
        "dunst": {
            "frame": "#89b4fa", "low_bg": "#1e1e2e", "low_fg": "#cdd6f4",
            "norm_bg": "#1e1e2e", "norm_fg": "#cdd6f4",
            "crit_bg": "#f38ba8", "crit_fg": "#1e1e2e",
        },
        "wall": HOME + "/Downloads/__usada_pekora_ookami_mio_shirogane_noel_miofa_and_dan_in_san_hololive_and_2_more_drawn_by_mori_nox__abb120e74edd9d75797b9dbc04690510-catppuccin-mocha.jpg",
    },
    "gruvbox": {
        "colors": {
            "fg": "#ebdbb2", "bg": "#282828", "red": "#fb4934",
            "cyan": "#8ec07c", "green": "#b8bb26", "lavender": "#504945",
            "light_blue": "#83a598", "grey": "#504945", "blue": "#83a598",
            "purple": "#d3869b", "yellow": "#fabd2f", "orange": "#fe8019",
            "teal": "#8ec07c",
        },
        "border": ("#fe8019", "#504945"),
        "dmenu": ("#282828", "#ebdbb2", "#fe8019", "#1d2021"),
        "gtk": ("gruvbox-dark", "oomox-gruvbox-dark"),
        "btop": "gruvbox_dark",
        "alacritty": {
            "bg": "#282828", "fg": "#ebdbb2",
            "black": "#282828", "red": "#cc241d", "green": "#98971a",
            "yellow": "#d79921", "blue": "#458588", "magenta": "#b16286",
            "cyan": "#689d6a", "white": "#a89984",
            "black_b": "#928374", "red_b": "#fb4934", "green_b": "#b8bb26",
            "yellow_b": "#fabd2f", "blue_b": "#83a598", "magenta_b": "#d3869b",
            "cyan_b": "#8ec07c", "white_b": "#ebdbb2",
        },
        "dunst": {
            "frame": "#fe8019", "low_bg": "#282828", "low_fg": "#ebdbb2",
            "norm_bg": "#282828", "norm_fg": "#ebdbb2",
            "crit_bg": "#cc241d", "crit_fg": "#ebdbb2",
        },
        "wall": HOME + "/Downloads/__shirogane_noel_hololive_drawn_by_ikkia__455b090d19a4ba4571105691fe5dba41.jpg",
    },
}


def current():
    try:
        with open(ACTIVE_FILE) as f:
            name = f.read().strip()
            if name in THEMES:
                return name
    except OSError:
        pass
    return None


def write_configs(name):
    th = THEMES[name]
    c = th["colors"]
    border = th["border"]
    dm = th["dmenu"]
    os.makedirs(os.path.dirname(WALL_CURRENT), exist_ok=True)
    os.makedirs(os.path.dirname(ALAC_FILE), exist_ok=True)
    os.makedirs(os.path.dirname(DUNST_FILE), exist_ok=True)
    os.makedirs(os.path.dirname(GTK3_FILE), exist_ok=True)
    os.makedirs(os.path.dirname(GTK4_FILE), exist_ok=True)

    with open(ACTIVE_FILE, "w") as f:
        f.write(name + "\n")

    # oxwm handoff (theme-current.lua)
    lua = ["return {"]
    for k, v in c.items():
        lua.append('  %s = "%s",' % (k, v))
    lua.append('  border_focus = "%s", border_unfocus = "%s",' % border)
    lua.append('  dmenu_nb = "%s", dmenu_nf = "%s",' % (dm[0], dm[1]))
    lua.append('  dmenu_sb = "%s", dmenu_sf = "%s",' % (dm[2], dm[3]))
    lua.append("}")
    with open(OXWM_FILE, "w") as f:
        f.write("-- generated by `theme`, do not edit\n")
        f.write("\n".join(lua) + "\n")

    # dmenu colors for shell scripts (clipmenu Mod+V reuses the same palette)
    with open(DMENU_ENV, "w") as f:
        f.write("# generated by `theme`, do not edit\n")
        f.write('DMENU_NB="%s"\n' % dm[0])
        f.write('DMENU_NF="%s"\n' % dm[1])
        f.write('DMENU_SB="%s"\n' % dm[2])
        f.write('DMENU_SF="%s"\n' % dm[3])

    # alacritty import (theme-current.toml)
    a = th["alacritty"]
    toml = (
        "[colors]\n"
        'primary = { background = "%s", foreground = "%s" }\n'
        "normal = {\n"
        '  black = "%s", red = "%s", green = "%s", yellow = "%s",\n'
        '  blue = "%s", magenta = "%s", cyan = "%s", white = "%s",\n'
        "}\n"
        "bright = {\n"
        '  black = "%s", red = "%s", green = "%s", yellow = "%s",\n'
        '  blue = "%s", magenta = "%s", cyan = "%s", white = "%s",\n'
        "}\n"
    ) % (a["bg"], a["fg"], a["black"], a["red"], a["green"], a["yellow"],
         a["blue"], a["magenta"], a["cyan"], a["white"], a["black_b"],
         a["red_b"], a["green_b"], a["yellow_b"], a["blue_b"], a["magenta_b"],
         a["cyan_b"], a["white_b"])
    with open(ALAC_FILE, "w") as f:
        f.write("# generated by `theme`, do not edit\n" + toml)

    # dunst runtime config (dunstrc.theme) - full file used via `-config`
    d = th["dunst"]
    ini = (
        "[global]\n"
        "    font = JetBrainsMono Nerd Font 10\n"
        "    width = 320\n"
        "    height = (0, 120)\n"
        "    offset = (12, 48)\n"
        "    origin = top-right\n"
        "    frame_width = 2\n"
        '    frame_color = "%s"\n'
        "    transparency = 20\n\n"
        "[urgency_low]\n"
        '    background = "%s"\n'
        '    foreground = "%s"\n'
        "    timeout = 6\n\n"
        "[urgency_normal]\n"
        '    background = "%s"\n'
        '    foreground = "%s"\n'
        "    timeout = 10\n\n"
        "[urgency_critical]\n"
        '    background = "%s"\n'
        '    foreground = "%s"\n'
        "    timeout = 0\n"
    ) % (d["frame"], d["low_bg"], d["low_fg"], d["norm_bg"], d["norm_fg"],
         d["crit_bg"], d["crit_fg"])
    with open(DUNST_FILE, "w") as f:
        f.write("# generated by `theme`, do not edit\n" + ini)

    # wallpaper
    wall = th.get("wall")
    if wall and os.path.exists(wall):
        shutil_copy(wall, WALL_CURRENT)
    else:
        print("warning: wallpaper image not found, keeping previous", file=sys.stderr)

    # GTK (gtk-3.0 + gtk-4.0 settings.ini). GTK apps read these at startup, so
    # re-launch apps after `theme apply`; GTK3/4 both honor the same keys.
    gtk_theme, gtk_icon = th["gtk"]
    gtk_ini = (
        "[Settings]\n"
        "gtk-theme-name=%s\n"
        "gtk-icon-theme-name=%s\n"
        "gtk-cursor-theme-name=Bibata-Modern-Classic\n"
        "gtk-cursor-theme-size=24\n"
        "gtk-font-name=JetBrainsMono Nerd Font 10\n"
        "gtk-application-prefer-dark-theme=1\n"
    ) % (gtk_theme, gtk_icon)
    head = "# generated by `theme`, do not edit\n"
    with open(GTK3_FILE, "w") as f:
        f.write(head + gtk_ini)
    with open(GTK4_FILE, "w") as f:
        f.write(head + gtk_ini)

    # btop (theme selection; takes effect on next launch - btop has no config
    # reload, so reopen a running btop after `theme apply`)
    os.makedirs(os.path.dirname(BTOP_CONF), exist_ok=True)
    btop_name = th.get("btop", "default")
    with open(BTOP_CONF, "w") as f:
        f.write(head + 'color_theme = "%s"\n' % btop_name)


def shutil_copy(src, dst):
    with open(src, "rb") as fi, open(dst, "wb") as fo:
        fo.write(fi.read())


def apply(name, restart=True):
    if name not in THEMES:
        sys.exit("unknown theme '%s'. Choices: %s" % (
            name, ", ".join(THEMES)))
    write_configs(name)
    display = os.environ.get("DISPLAY")
    if restart and display:
        # Wallpaper (feh roots the current.jpg)
        subprocess.call(["feh", "--bg-fill", WALL_CURRENT],
                        stderr=subprocess.DEVNULL)
        # Restart dunst with the themed config (comm is ".dunst-wrapped", so
        # pkill must match the wrapped name with a regex)
        subprocess.call(["pkill", "dunst"],
                        stderr=subprocess.DEVNULL)
        subprocess.Popen(
            ["setsid", "dunst", "-config", DUNST_FILE],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL)
        # Reload oxwm (config + bar colors come from theme-current.lua)
        subprocess.call(["xdotool", "key", "--clearmodifiers", "super+shift+r"],
                        stderr=subprocess.DEVNULL)
        # Live-reload running alacritty instances (best effort)
        subprocess.call(["alacritty", "msg", "config"], stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL)
    print("theme applied: %s" % name)


def ensure():
    name = current() or "tokyonight"
    missing = [p for p in (OXWM_FILE, ALAC_FILE, DUNST_FILE, WALL_CURRENT,
                           GTK3_FILE, GTK4_FILE, BTOP_CONF, DMENU_ENV)
               if not os.path.exists(p)]
    if missing:
        write_configs(name)
        print("theme ensure: wrote missing files for %s" % name)
    else:
        print("theme ensure: nothing to do (%s)" % name)


def main(argv):
    cmd = argv[0] if argv else "help"
    if cmd in ("list", "ls"):
        for n in THEMES:
            mark = "*" if n == current() else " "
            print("%s %s" % (mark, n))
    elif cmd == "current":
        print(current() or "none")
    elif cmd == "apply":
        apply(argv[1] if len(argv) > 1 else current() or "tokyonight")
    elif cmd == "ensure":
        ensure()
    else:
        sys.exit("usage: theme apply <theme> | list | current | ensure")


if __name__ == "__main__":
    main(sys.argv[1:])
PYEOF