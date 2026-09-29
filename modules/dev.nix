{
  flake.homeManagerModules.dev = { pkgs, ... }: {
    home.packages = with pkgs; [
      python3
      gcc
      cmake
      ninja
      bear
      lldb
      gersemi
      clang-tools
      cppcheck
      valgrind
      rustc
      cargo
      rust-analyzer
      rustfmt
      clippy
      android-tools
      payload-dumper-go
    ];
  };
}
