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
    nixos apply ".#home-lab" --target-host {{ home-lab-target }} --build-host {{ home-lab-target }} --remote-root --yes

home-lab-debug: check
    nixos apply ".#home-lab" --target-host {{ home-lab-target }} --build-host {{ home-lab-target }} --remote-root --show-trace --verbose --yes

# Build the production home-lab closure without deploying it.
home-lab-build:
    nix build ".#nixosConfigurations.home-lab.config.system.build.toplevel" --no-link -L

# Run the isolated home-lab integration test.
home-lab-test:
    nix build ".#checks.x86_64-linux.home-lab-integration" --no-link -L

# Build a QEMU VM of home-lab (only virtualisation.vmVariant overrides apply).
# Login: mr-nix / vm (console and SSH); root / vm (console only).
# SSH: 127.0.0.1:2222.
# Exit serial console: Ctrl-a then x.
home-lab-vm:
    nix build ".#nixosConfigurations.home-lab.config.system.build.vm" -o result-home-lab-vm

home-lab-vm-run: home-lab-vm
    ./result-home-lab-vm/bin/run-*-vm

# Build a QEMU VM of test-bed (graphical Home Manager layout preview).
# Login: mr-fw16 / preview  or  root / preview.  SSH: localhost:2224.
test-bed-vm:
    nix build ".#nixosConfigurations.test-bed.config.system.build.vm" -o result-test-bed-vm

test-bed-vm-run: test-bed-vm
    ./result-test-bed-vm/bin/run-*-vm

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

############################################################################
#
#  Home Manager — standalone user config (non-NixOS, e.g. Framework 16)
#
############################################################################

home-target := "mr-fw16@fw16"

# Activate the standalone Home Manager config (first run renames colliding dotfiles to *.hm-bak).
home cfg=home-target: check
    home-manager switch --flake ".#{{ cfg }}" -b hm-bak

# Build the activation package without switching (result symlink).
home-build cfg=home-target:
    home-manager build --flake ".#{{ cfg }}"

# Show Home Manager news for the config.
home-news cfg=home-target:
    home-manager news --flake ".#{{ cfg }}"
