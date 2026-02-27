# Credits - https://nixos-and-flakes.thiscute.world/best-practices/simplify-nixos-related-commands
# just is a command runner, Justfile is very similar to Makefile, but simpler.
############################################################################
#
#  Nix commands related to the local machine
#
############################################################################

deploy: check
    nixos apply . --remote-root

debug: check
    nixos apply . --remote-root --show-trace --verbose

up:
    nix flake update

check:
    nix flake check

# Update specific input, usage: make upp i=home-manager
upp:
    nix flake update $(i)

history:
    nix profile history --profile /nix/var/nix/profiles/system

repl:
    nix repl -f flake:nixpkgs

# remove all generations older than 7 days
clean:
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

# garbage collect all unused nix store entries
gc:
    sudo nix-collect-garbage --delete-old

############################################################################
#
#  Commands related to my servers
#
############################################################################

home-lab-target := "mr-nix@${TARGET_HOST:-home-lab}"

home-lab: check
    nixos apply ".#home-lab" --target-host {{ home-lab-target }} --build-host {{ home-lab-target }} --remote-root

home-lab-debug: check
    nixos apply ".#home-lab" --target-host {{ home-lab-target }} --build-host {{ home-lab-target }} --remote-root --show-trace --verbose
