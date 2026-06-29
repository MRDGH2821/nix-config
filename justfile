# Credits - https://nixos-and-flakes.thiscute.world/best-practices/simplify-nixos-related-commands
# just is a command runner, Justfile is very similar to Makefile, but simpler.
############################################################################
#
#  Nix commands related to the local machine
#
############################################################################

deploy: check
    nixos apply . --local-root

debug: check
    nixos apply . --local-root --show-trace --verbose

up:
    nix flake update

check:
    nix flake check

# Update specific input, usage: just upp nixpkgs
upp i="nixpkgs":
    nix flake update {{ i }}

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

############################################################################
#
#  Provisioning — first-time install on bare metal / VMs
#
############################################################################

# Initial NixOS installation on a remote machine (no NixOS yet).
# Requires TARGET_HOST env var (e.g. from .envrc.local or direnv).
provision: check
    nixos-anywhere --flake ".#home-lab" "root@${TARGET_HOST}"

# Generate a hardware-configuration.nix from a remote machine.
# Useful when bringing up new hardware.
gen-hw-config:
    nixos-anywhere --generate-hardware-config nixos-generate-config \
        ./nix/hosts/home-lab/hardware-configuration.nix \
        "root@${TARGET_HOST}"
