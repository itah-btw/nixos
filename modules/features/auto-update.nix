_: {
  flake.modules.nixos.autoUpdate =
    { config, pkgs, ... }:
    let
      user = config.users.users.itah;
      flakePath = "${user.home}/Nixos";
    in
    {
      system.autoUpgrade = {
        enable = true;
        flake = flakePath;
        operation = "switch";
        allowReboot = false;

        # With a flake, --upgrade only applies to channels; the inputs are
        # refreshed explicitly instead.
        upgrade = false;
        flags = [
          "--update-input"
          "nixpkgs"
          "--update-input"
          "home-manager"
          "--update-input"
          "flake-parts"
          "--update-input"
          "import-tree"
        ];

        dates = "weekly";
        randomizedDelaySec = "1h";
        persistent = true;
      };

      # The lock file is updated in place but not committed. Review and commit
      # it when convenient.
      #
      # The upgrade service runs as root, so `--update-input` would leave
      # flake.lock owned by root. Give it back to the user even when the rebuild
      # fails. The leading "-" tells systemd to ignore a missing file.
      systemd.services.nixos-upgrade.serviceConfig.ExecStopPost = [
        "-${pkgs.coreutils}/bin/chown ${user.name}:${user.group} ${flakePath}/flake.lock"
      ];
    };
}
