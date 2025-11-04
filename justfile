# Credits - https://nixos-and-flakes.thiscute.world/best-practices/simplify-nixos-related-commands
# just is a command runner, Justfile is very similar to Makefile, but simpler.
############################################################################
#
#  Nix commands related to the local machine
#
############################################################################

deploy:
    nixos-rebuild switch --flake . --use-remote-sudo

debug:
    nixos-rebuild switch --flake . --use-remote-sudo --show-trace --verbose

up:
    nix flake update

check:
    nix flake check

# Update specific input

# usage: make upp i=home-manager
upp:
    nix flake update $(i)

history:
    nix profile history --profile /nix/var/nix/profiles/system

repl:
    nix repl -f flake:nixpkgs

clean:
    # remove all generations older than 7 days
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

gc:
    # garbage collect all unused nix store entries
    sudo nix-collect-garbage --delete-old

############################################################################
#
#  Idols, Commands related to my remote distributed building cluster
#
############################################################################

home-lab:
    nixos-rebuild-ng --flake .#home-lab --target-host mr-nix@home-lab --build-host mr-nix@home-lab switch --use-remote-sudo

home-lab-debug:
    nixos-rebuild-ng --flake .#home-lab --target-host mr-nix@home-lab --build-host mr-nix@home-lab switch --use-remote-sudo --show-trace --verbose
