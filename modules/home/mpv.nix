{
  flake.homeManagerModules.mpv = {
    programs.mpv = {
      enable = true;
      config = {
        hwdec = "auto";
      };
    };
  };
}
