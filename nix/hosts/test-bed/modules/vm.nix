# QEMU guest profile + VM sizing. test-bed is VM-only — not bare metal.
{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  virtualisation = {
    cores = 4;
    diskSize = 20480; # MiB
    forwardPorts = [
      {
        from = "host";
        guest.port = 22;
        host = {
          address = "127.0.0.1";
          port = 2224;
        };
      }
    ];
    graphics = true;
    memorySize = 8192;
  };
}
