{
  flake.homeManagerModules.identity = { constants, ... }: {
    home.username = constants.username;
    home.homeDirectory = "/home/${constants.username}";
    programs.home-manager.enable = true;

    programs.git = {
      enable = true;
      settings = {
        user.name = constants.username;
        user.email = "103980435+itah-btw@users.noreply.github.com";
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        fetch.prune = true;
        merge.conflictStyle = "zdiff3";
        rerere.enabled = true;
        commit.verbose = true;
      };
    };
  };
}
