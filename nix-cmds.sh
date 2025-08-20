#!/usr/bin/env bash

# NixOS Anywhere deployment script
# Set environment variables before running this script:
# export TARGET_HOST=192.168.1.150  # Replace with your target server IP
# export TARGET_USER=root           # Replace with your target username (optional)
#
# Alternatively, copy .envrc.local.sample to .envrc.local and customize it

# Source local config if it exists
if [[ -f "./.envrc" ]]; then
    # shellcheck source=./.envrc
    source ./.envrc
fi

# Default values (override with environment variables)
USER=${TARGET_USER:-root}
HOST_IP=${TARGET_HOST:-""}
FLAKE=${TARGET_FLAKE:-"./nix/hosts/home-lab#home-lab"}
HOST_FOLDER=${TARGET_HOST_FOLDER:-"./nix/hosts/home-lab"}

# Validate that HOST is set properly and not empty
if [[ -z ${HOST_IP} || ${HOST_IP} == "" ]]; then
    echo "Error: TARGET_HOST is not set or is empty"
    echo "Please set the TARGET_HOST environment variable or create a .envrc.local file"
    echo ""
    echo "Example 1: Environment variable"
    echo "  export TARGET_HOST=192.168.1.150"
    echo "  ./nix-cmds.sh"
    echo ""
    echo "Example 2: Local config file"
    echo "  cp .envrc.local.sample .envrc.local"
    echo "  # Edit .envrc.local with your settings"
    echo "  ./nix-cmds.sh"
    exit 1
fi

# Additional validation for valid IP format (basic check)
if [[ ! ${HOST_IP} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "Warning: TARGET_HOST does not appear to be a valid IP address format: ${HOST_IP}"
    echo "Continuing anyway as it might be a hostname..."
fi

echo "Deploying to: ${USER}@${HOST_IP}"

nix_anywhere() {
    echo "About to run nixos-anywhere deployment..."
    echo "Target: ${USER}@${HOST_IP}"
    echo "Flake: ${FLAKE}"
    echo ""
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        return 1
    fi

    sudo nix run github:nix-community/nixos-anywhere --extra-experimental-features nix-command --extra-experimental-features flakes -- "$@" --flake "${FLAKE}"
}

generate_hardware_config() {
    echo "Running hardware configuration generation..."
    echo "Target: ${USER}@${HOST_IP}"
    echo "Output: ${HOST_FOLDER}/hardware-configuration.nix"
    echo ""
    read -p "Continue with hardware config generation? (y/N): " -n 1 -r
    echo
    if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
        echo "Hardware config generation cancelled."
        return 1
    fi

    nix_anywhere --target-host "${USER}"@"${HOST_IP}" --generate-hardware-config nixos-generate-config "${HOST_FOLDER}"/hardware-configuration.nix
}

# nix_anywhere --help

# nix_anywhere --target-host root@<YOUR_TARGET_IP> --generate-hardware-config nixos-generate-config ./hardware-configuration.nix

# Run hardware configuration generation
# generate_hardware_config

nixos_rebuild() {
    HOST=mr-nix@"${HOST_IP}"

    if [[ "${HOST_IP}" != "localhost" ]]; then
        nixos-rebuild switch --flake "${FLAKE}" --target-host "${HOST}" --build-host "${HOST}" --verbose
    else
        sudo nixos-rebuild switch --flake "${FLAKE}" --target-host "${HOST}" --build-host "${HOST}" --verbose
    fi
}

nixos_rebuild
