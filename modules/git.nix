{
  flake.homeManagerModules.git = { constants, ... }: {
    programs.git = {
      enable = true;
      settings = {
        user.name = constants.username;
        user.email = "103980435+itah-btw@users.noreply.github.com";
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };
  };
}
