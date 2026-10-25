{ ... }:
{
  flake.modules.homeManager.noctalia = { pkgs, ... }: {
    programs.noctalia = {
      enable = true;
      package = pkgs.noctalia;
      systemd.enable = false;
      checkConfig = true;
      settings = {
        bar.default = {
          position = "top";
          thickness = 28;
          margin_ends = 0;
          panel_overlap = 1;
          radius = 0;
          capsule = false;
          font_family = "JetBrainsMono Nerd Font";
          font_weight = 700;
          font_scale = 1.1;
          background_opacity = 1.0;
          compositor_blur = true;
          start = [ "workspaces" "sep" "umbriel" "sep" "active_window" ];
          center = [ "clock" "sep" "weather" ];
          end = [
            "media"
            "sep"
            "ram"
            "sep"
            "cpu"
            "sep"
            "temp"
            "sep"
            "network"
            "sep"
            "volume"
            "sep"
            "brightness"
            "sep"
            "bat"
          ];
          widget_spacing = 6;
          padding = 8;
        };

        widget = {
          workspaces = {
            type = "workspaces";
            style = "regular";
            show_labels = true;
            label_source = "id";
            change_color_on_hover = true;
          };
          umbriel = {
            type = "noctalia/umbriel-companion:bar";
          };
          active_window = {
            type = "active_window";
          };
          sep = {
            type = "text";
            color = "#585b70";
            text = "│";
          };
          media = {
            type = "media";
            color = "#cba6f7";
            hide_when_no_media = false;
          };
          ram = {
            type = "sysmon";
            stat = "ram_used";
            color = "#89b4fa";
            highlight_color = "error";
            visualization = "none";
            show_glyph = true;
            show_value = true;
            label_show_units = true;
          };
          cpu = {
            type = "sysmon";
            stat = "cpu_usage";
            color = "#f9e2af";
            highlight_color = "error";
            visualization = "none";
            show_glyph = true;
            show_value = true;
            label_show_units = true;
          };
          temp = {
            type = "sysmon";
            stat = "cpu_temp";
            color = "#fab387";
            highlight_color = "error";
            visualization = "none";
            show_glyph = true;
            show_value = true;
            label_show_units = true;
          };
          clock = {
            type = "clock";
            color = "#cba6f7";
            format = "󰃭 {:%a, %b %d - %H:%M}";
          };
          bat = {
            type = "battery";
            color = "#a6e3a1";
            display_mode = "glyph";
            show_label = true;
            label_content = "percent";
          };
          network = {
            type = "network";
            color = "#89dceb";
          };
          volume = {
            type = "volume";
            color = "#94e2d5";
          };
          brightness = {
            type = "brightness";
            color = "#f9e2af";
          };
          weather = {
            type = "weather";
            color = "#89dceb";
          };
        };

        plugins.enabled = [ "noctalia/wallhaven" "noctalia/umbriel-companion" ];

        shell.font_family = "JetBrainsMono Nerd Font";

        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
        };
      };
    };
  };
}