{
  flake.nixosModules.virt =
    {
      constants,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        qemu
        OVMF.fd
        (writeShellScriptBin "vm" ''
          export VM_HOME="/home/${constants.username}/Projects/vm"
          exec "$VM_HOME/vm.sh" "$@"
        '')
      ];

      environment.variables = {
        OVMF_CODE = "${pkgs.OVMF.fd}/FV/OVMF_CODE.fd";
        OVMF_VARS = "${pkgs.OVMF.fd}/FV/OVMF_VARS.fd";
      };
    };
}
