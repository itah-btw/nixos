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
          font_scale = 1.0;
          background_opacity = 1.0;
          compositor_blur = true;
          start = [ "workspaces" ];
          center = [ "clock" "weather" ];
          end = [
            "ram"
            "cpu"
            "temp"
            "battery"
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
          ram = {
            type = "sysmon";
            stat = "ram_used";
            show_glyph = false;
            show_value = true;
            label_show_units = true;
            custom_label = "Ram:";
          };
          cpu = {
            type = "sysmon";
            stat = "cpu_usage";
            show_glyph = false;
            show_value = true;
            label_show_units = true;
            custom_label = "CPU:";
          };
          temp = {
            type = "sysmon";
            stat = "cpu_temp";
            show_glyph = false;
            show_value = true;
            label_show_units = true;
            custom_label = "Temp:";
          };
          clock = {
            type = "clock";
            format = "{:%a, %b %d - %-I:%M %P}";
          };
          weather = {
            type = "weather";
          };
          battery = {
            type = "battery";
            display_mode = "glyph";
            show_label = true;
            label_content = "percent";
          };
        };

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