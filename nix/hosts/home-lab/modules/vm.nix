# Overrides applied only for `system.build.vm` / `nixos-rebuild build-vm`.
# Does not affect bare metal deploys of home-lab.
{lib, ...}: {
  virtualisation.vmVariant = {
    imports = [../../../tests/home-lab/sandbox.nix];
    virtualisation = {
      fileSystems."/nix/.ro-store" = {
        device = "nix-store";
        fsType = "9p";
        neededForBoot = true;
        options = [
          "trans=virtio"
          "version=9p2000.L"
          "ro"
          "x-systemd.requires=modprobe@9pnet_virtio.service"
        ];
      };
      forwardPorts = lib.mkForce [
        {
          from = "host";
          guest.port = 22;
          host = {
            address = "127.0.0.1";
            port = 2222;
          };
        }
        {
          from = "host";
          guest.port = 80;
          host = {
            address = "127.0.0.1";
            port = 8080;
          };
        }
        {
          from = "host";
          guest.port = 443;
          host = {
            address = "127.0.0.1";
            port = 8443;
          };
        }
      ];
      graphics = false; # serial console (Ctrl-a x to exit QEMU)
      qemu.options = [
        "-virtfs local,path=${builtins.storeDir},security_model=none,mount_tag=nix-store,readonly=on"
      ];
      restrictNetwork = lib.mkForce true;
      # Drop qemu-vm's writable xchg/shared host directories.
      sharedDirectories = lib.mkForce {};
      useHostCerts = lib.mkForce false;
    };
  };
}
