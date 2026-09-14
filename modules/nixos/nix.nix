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
  systemd.services.nix-gc.serviceConfig.ExecStartPost = "${pkgs.nix}/bin/nix-store --optimise";

  nixpkgs.config.allowUnfree = true;
}
