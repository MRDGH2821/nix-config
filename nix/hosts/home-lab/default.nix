{
  modulesPath,
  lib,
  pkgs,
  ...
}@args:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    ../../modules/features/ssh.nix
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  services.openssh.enable = true;

  environment.systemPackages =
    with pkgs;
    map lib.lowPrio [
      curl
      gitMinimal
      neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      git
      wget
      curl
    ];

  programs.ssh.startAgent = true;
  networking = {
    # configures the network interface(include wireless) via `nmcli` & `nmtui`
    networkmanager.enable = true;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDVfzHbNxtB2c2qPKMXTYHnxDx4O+cJ1y2LqdOda1h2bKwmfaM81poecVluny4B21Zv3axNTnlMmBs0nucgTN8xcQgfM66Eg5dq2Hgu79mA6aKXt3AIx1sMPwOtjSA6vpnUCk+DcKX2HfTPdMLVC7XRHpMqcCfaemIq5fcdGfhPkLs0mLP7NoIcPeFSPTiNfVQ+/BE2gj7110L1DmS2Y6K+PFehxaiYUMeokqQyRk/KVgYoZi+6O70PIWsswLepQYUhmMAZfIJiN3NjpsM0AMWFLEpMDzgztCZoFOYaNuVPog/VQiHVwvDYKmwR99MoCAX/hHvfJN+rGcc2mAARtO2EWkB3hh0jm7Y0Ojgc2BQkbtJRBp8Z313/nWHkyEsXEGeIs4wHa7fWygmSw+/FNLkeB5OotJ1iCB19b6KLWNmbRI4ka06MY2MmAAeWVx4fLTemzN1rtt4xf6VzoKA3JSeWhbYpoRtQfPNH6+qocaXRuHF16U8ES2sRkSM+L2Ta4+s= ask.mrdgh2821@outlook.com"
  ]
  ++ (args.extraPublicKeys or [ ]); # this is used for unit-testing this module and can be removed if not needed

  system.stateVersion = "25.05";
}
