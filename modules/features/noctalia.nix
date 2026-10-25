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
          center = [ ];
          end = [
            "media"
            "sep"
            "ram"
            "sep"
            "cpu"
            "sep"
            "temp"
            "sep"
            "batlabel"
            "bat"
            "sep"
            "clock"
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
            focused_color = "#0db9d7";
            occupied_color = "#0db9d7";
            empty_color = "#bbbbbb";
            urgent_color = "#f7768e";
            change_color_on_hover = true;
          };
          umbriel = {
            type = "noctalia/umbriel-companion:bar";
          };
          active_window = {
            type = "active_window";
            color = "#6dade3";
          };
          media = {
            type = "media";
            color = "#ad8ee6";
          };
          ram = {
            type = "sysmon";
            stat = "ram_used";
            color = "#7aa2f7";
            visualization = "none";
            show_glyph = false;
            show_value = true;
            label_show_units = true;
            custom_label = "Ram:";
          };
          cpu = {
            type = "sysmon";
            stat = "cpu_usage";
            color = "#f7768e";
            visualization = "none";
            show_glyph = false;
            show_value = true;
            label_show_units = true;
            custom_label = "CPU:";
          };
          temp = {
            type = "sysmon";
            stat = "cpu_temp";
            color = "#ad8ee6";
            visualization = "none";
            show_glyph = false;
            show_value = true;
            label_show_units = true;
            custom_label = "Temp:";
          };
          sep = {
            type = "text";
            color = "#a9b1d6";
            text = "│";
          };
          sepw = {
            type = "text";
            color = "#a9b1d6";
            text = "│";
          };
          clock = {
            type = "clock";
            color = "#0db9d7";
            format = "{:%a, %b %d - %H:%M}";
          };
          batlabel = {
            type = "text";
            color = "#9ece6a";
            text = "Bat:";
          };
          bat = {
            type = "battery";
            color = "#9ece6a";
            display_mode = "none";
            show_label = true;
            label_content = "percent";
          };
        };

        plugins.enabled = [ "noctalia/wallhaven" "noctalia/umbriel-companion" ];

        shell.font_family = "JetBrainsMono Nerd Font";

        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Tokyo-Night";
        };
      };
    };
  };
}