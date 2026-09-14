{...}: {
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    # Hands-free optimization without the per-build latency of
    # auto-optimise-store (which re-scans the store on every build).
    trusted-users = ["root" "@wheel"];
    # /etc/nixos is a live git checkout edited between rebuilds; don't warn
    # about the dirty tree on every nixos-option / nix eval.
    warn-dirty = false;
  };

  # Periodic store dedup: run weekly, replacing auto-optimise-store.
  nix.optimise = {
    automatic = true;
    dates = ["weekly"];
  };

  # Automatic garbage collection: run weekly, free anything older than 7 days.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nixpkgs.config.allowUnfree = true;
}
