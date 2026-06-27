# Nix Home lab

[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/refs/heads/master/img/badge/black-badge.json)](https://github.com/copier-org/copier)

My config for Home Lab powered using NixOS.

## Setup

Enter the development shell first (provides `just`, `sops`, `git-agecrypt`, and other tools):

```bash
direnv allow
```

### Configuration

Set your target host before deploying. You have two options:

#### Option 1: Environment variable

```bash
export TARGET_HOST=192.168.1.150 # Replace with your target server IP or hostname
```

#### Option 2: Local configuration file

```bash
cp .envrc.local.sample .envrc.local
# Edit .envrc.local with your settings
```

`.envrc` loads `.envrc.local` automatically when present.

### Usage

Validate the flake, then deploy:

```bash
just check          # validate flake syntax and dependencies
just home-lab       # deploy .#home-lab to mr-nix@${TARGET_HOST}
just home-lab-debug # remote deploy with verbose trace output
```

Other useful commands:

```bash
just deploy        # apply to the local machine
just provision     # first-time install via nixos-anywhere (uses root@${TARGET_HOST})
just gen-hw-config # generate hardware-configuration.nix from a remote host
just up            # update all flake inputs
just upp i=nixpkgs # update a specific input
```

Run `just` with no arguments to list all recipes.

### Secrets

Sensitive values are managed with [SOPS](https://github.com/getsops/sops) and
[git-agecrypt](https://github.com/bartei/git-agecrypt). After cloning, register
your age or SSH identity and re-checkout encrypted files:

```bash
direnv allow
git-agecrypt config add -i ~/.config/age/your-key.txt
git checkout -- nix/hosts/home-lab/secrets/agecrypt/
```

See [nix/hosts/home-lab/secrets/README.md](./nix/hosts/home-lab/secrets/README.md)
for full setup, viewing commands, and troubleshooting.

## Licence

See [LICENCE](./LICENCE.txt)
