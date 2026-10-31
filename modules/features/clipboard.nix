_: {
  flake.modules.homeManager.clipboard = _: {
    services.wl-clip-persist = {
      enable = true;
      clipboardType = "both";
      systemdTargets = [ "graphical-session.target" ];
    };

    services.cliphist = {
      enable = true;
      systemdTargets = [ "graphical-session.target" ];
    };
  };
}
