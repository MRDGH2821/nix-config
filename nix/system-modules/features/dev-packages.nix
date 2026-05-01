{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    age
    cachix
    compose2nix
    git-agecrypt
    lazygit
    nixd
    nixos-rebuild-ng
    nixpkgs-fmt
    nixpkgs-review
    sops
    ssh-to-age
    uv
  ];
}
