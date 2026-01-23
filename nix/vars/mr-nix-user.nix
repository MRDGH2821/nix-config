{pkgs, ...}: {
  # username = "mr-nix";
  programs.zsh.enable = true;
  users.users.mr-nix = {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDVfzHbNxtB2c2qPKMXTYHnxDx4O+cJ1y2LqdOda1h2bKwmfaM81poecVluny4B21Zv3axNTnlMmBs0nucgTN8xcQgfM66Eg5dq2Hgu79mA6aKXt3AIx1sMPwOtjSA6vpnUCk+DcKX2HfTPdMLVC7XRHpMqcCfaemIq5fcdGfhPkLs0mLP7NoIcPeFSPTiNfVQ+/BE2gj7110L1DmS2Y6K+PFehxaiYUMeokqQyRk/KVgYoZi+6O70PIWsswLepQYUhmMAZfIJiN3NjpsM0AMWFLEpMDzgztCZoFOYaNuVPog/VQiHVwvDYKmwR99MoCAX/hHvfJN+rGcc2mAARtO2EWkB3hh0jm7Y0Ojgc2BQkbtJRBp8Z313/nWHkyEsXEGeIs4wHa7fWygmSw+/FNLkeB5OotJ1iCB19b6KLWNmbRI4ka06MY2MmAAeWVx4fLTemzN1rtt4xf6VzoKA3JSeWhbYpoRtQfPNH6+qocaXRuHF16U8ES2sRkSM+L2Ta4+s= ask.mrdgh2821@outlook.com"
    ];
    isNormalUser = true;
    extraGroups = [
      "docker"
      "podman"
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.allowed-users = ["@wheel" "mr-nix"];

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };
}
