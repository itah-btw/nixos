# C/C++ toolchain, for nvim: the LSP/lint configs resolve every tool by absolute
# store path, so this is the only thing that puts one on the wrapper's PATH.
{
  flake.homeManagerModules.c-toolchain = { pkgs, ... }: {
    home.packages = with pkgs; [
      gcc
      cmake
      ninja
      # Compilation database for clangd.
      bear
      # The dap.debugger option.
      lldb
      # nixfmt's equivalent, for conform.nvim.
      gersemi
      clang-tools
      cppcheck
      valgrind
    ];
  };
}
