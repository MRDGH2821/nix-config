# Nix Home lab

[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/refs/heads/master/img/badge/black-badge.json)](https://github.com/copier-org/copier)

My config for Home Lab powered using NixOS.

## Setup

### Configuration

Before running the deployment script, you need to set your target host IP address. You have two options:

#### Option 1: Environment Variables

```bash
export TARGET_HOST=192.168.1.150  # Replace with your target server IP
export TARGET_USER=root           # Optional, defaults to root
```

#### Option 2: Local Configuration File

```bash
# Copy the example config and customize it
cp config.example.sh config.local.sh
# Edit config.local.sh with your specific settings
```

### Usage

Once configured, you can run the deployment commands:

```bash
# Run the deployment script
./nix-cmds.sh
```
