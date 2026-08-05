# Overrides applied only for `system.build.vm` / `nixos-rebuild build-vm`.
# Does not affect bare metal deploys of home-lab.
{lib, ...}: {
  virtualisation.vmVariant = {
    security.pam.services = {
      login.u2fAuth = lib.mkForce false;
      sudo.u2fAuth = lib.mkForce false;
    };
    # Console login: production uses SSH keys + U2F, neither works alone in a local VM.
    users.users = {
      mr-nix.initialPassword = "vm";
      root.initialPassword = "vm";
    };
    # Enough RAM for pods + lab services; tune if the host is tight.
    virtualisation = {
      cores = 4;
      diskSize = 20480; # MiB guest disk image
      forwardPorts = [
        {
          from = "host";
          guest.port = 22;
          host.port = 2222;
        }
      ];
      graphics = false; # serial console (Ctrl-a x to exit QEMU)
      memorySize = 8192;
    };
  };
}
