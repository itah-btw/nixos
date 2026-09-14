{pkgs, ...}: {
  # Upstream config pinned as-is (github.com/tonybanters/nvim @ 086d1b3).
  # Bump `rev`, re-prefetch the hash, and rebuild. The store copy is read-only,
  # so `:Lazy update` can't write lazy-lock.json — plugin updates need a writable checkout.
  xdg.configFile."nvim".source = pkgs.fetchzip {
    url = "https://github.com/tonybanters/nvim/archive/086d1b3.tar.gz";
    hash = "sha256-UHV6lwSjlatQjv4ccwS1V6cq86syU9n95fh3jeq8MWw=";
  };
}
