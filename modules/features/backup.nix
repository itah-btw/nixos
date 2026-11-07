_: {
  flake.modules.nixos.backup = { config, pkgs, ... }: {
    # Versioned backups of the home directory. The repository below is local by
    # default; point it at an external drive or remote for real disaster
    # recovery (e.g. "/run/media/itah/Backup/borg/home" or "ssh://...").
    services.borgbackup.jobs.home = {
      paths = [ "/home/itah" ];
      repo = "/var/backups/borg/home";
      encryption.mode = "none";
      compression = "zstd,3";
      startAt = "daily";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      exclude = [
        "/home/itah/.cache"
        "/home/itah/.local/share/Trash"
        "/home/itah/Android/Sdk"
        "/home/itah/.npm"
        "/home/itah/.cargo/registry"
      ];
    };
  };
}