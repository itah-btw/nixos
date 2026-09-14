{pkgs, ...}: {
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["root" "@wheel"];
    # /etc/nixos is a live git checkout between rebuilds; silence the dirty-tree warning.
    warn-dirty = false;
  };

  # Weekly maintenance in one timer: GC drops generations older than 7 days,
  # then nix-store --optimise dedups the store in the same run (ExecStartPost).
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  systemd.services.nix-gc.serviceConfig.ExecStartPost = [
    "${pkgs.nix}/bin/nix-store --optimise"
    (pkgs.writeShellScript "nix-gc-notify" ''
      set -u
      export PATH=/run/current-system/sw/bin:$PATH
      [ -e /run/user/1000/bus ] || exit 0
      runuser -u itah -- env DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
        notify-send -t 8000 -h string:synchronous:nix-gc "Nix GC complete" \
        "Generations older than 7 days deleted, store optimized" || true
    '')
  ];

  nixpkgs.config.allowUnfree = true;
}
