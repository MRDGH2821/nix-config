{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    age
    compose2nix
    git-agecrypt
    nil
    nixos-rebuild-ng
    nixpkgs-fmt
    nixpkgs-review
    sops
    ssh-to-age
  ];
}
