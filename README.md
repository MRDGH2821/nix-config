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

### Local home-lab build, VM, and integration test

These recipes build or run locally; they do not deploy to a host. They do not
depend on `TARGET_HOST`:

```bash
just home-lab-build # build the production home-lab system closure only
just home-lab-test  # build/run the isolated home-lab integration check
just home-lab-vm    # build the local QEMU VM
just home-lab-vm-run
```

The VM and integration test use the local-only `homelab.test` domain and test
fixtures. The interactive VM forwards SSH `127.0.0.1:2222` to guest port 22,
HTTP `127.0.0.1:8080` to port 80, and HTTPS `127.0.0.1:8443` to port 443;
all host forwards bind to loopback, not the LAN. The sandbox configures
`git.homelab.test` as a fixture Traefik route to Forgejo; its wildcard TLS
certificate is self-signed. Use `mr-nix` / `vm` for console login and SSH.
`root` / `vm` is console-only; root SSH is disabled.

All fixture credentials and private keys are deliberately public. Never use
them outside this sandbox. The common application password is
`homelab-test-password`:

| Application | Login                                  |
| ----------- | -------------------------------------- |
| Authentik   | `akadmin` (email `admin@homelab.test`) |
| Nextcloud   | `mrdgh2821`                            |
| pgAdmin     | `admin@example.org`                    |

Access the fixture Forgejo route without changing your workstation's DNS:

```bash
curl --cacert nix/tests/home-lab/fixtures/cert.pem \
  --connect-to git.homelab.test:443:127.0.0.1:8443 \
  https://git.homelab.test/api/healthz
```

The VM guest has restricted network access. The integration check asserts
blocked connections to `1.1.1.1:443` and QEMU's `10.0.2.2` ports 22 and 80.
The integration test client can connect to the server's PostgreSQL port 5432,
but the tested PostgreSQL login attempt is rejected. Do not interpret the TCP
check as evidence that the port is private.

The VM and integration test must never use production data, credentials, or
keys. The interactive VM uses a 30 GiB disk and 12 GiB RAM, and stores disk
state in `$PWD/home-lab.qcow2` by default (or the file selected by
`NIX_DISK_IMAGE`). A fresh disk starts with empty application/database state;
retaining it preserves test data. To reset, delete only the identified
sandbox disk. The integration test server has a separate disposable 40 GiB
disk and 12 GiB RAM.

Keep large manual VM disks and QEMU scratch files on a disk-backed filesystem
with enough free space for the growing guest disk, image unpacking, and any
concurrent builds. Avoid memory-backed `/tmp` (often tmpfs): a sparse qcow2
file can grow by tens of GiB and exhaust it. For a separate manual smoke run,
use a disk-backed directory, for example:

```bash
mkdir -p "$HOME/.local/state/homelab-test/tmp"
TMPDIR="$HOME/.local/state/homelab-test/tmp" \
  NIX_DISK_IMAGE="$HOME/.local/state/homelab-test/smoke.qcow2" \
  just home-lab-vm-run
```

The first build downloads approximately 6 GiB of pinned container archives
in addition to Nix dependencies. Both VM modes use the shared
`homelab-test-images.service` oneshot before any OCI container starts. It
checks each of the four distinct pinned image references against its expected
image ID, loading the local archive only when the reference is absent or its
ID differs, then verifies the loaded ID. A missing or mismatched image fails
startup. The loader remains active for the boot, so Honcho's three units share
one import and migration/API recovery restarts do not reload archives. On
reboot or a changed loader definition, IDs are checked again, including fixture
updates under unchanged tags. Every container uses `pull=never`; guests must
not pull images from the network.
Changing a production image reference requires updating its entry in
`nix/tests/home-lab/images.nix`; the sandbox rejects a mismatched reference.
Tests freeze each registry image to a digest. Production mutable tags such
as `latest` can still move independently, so a passing test does not certify
a newer image later pulled under the same tag.

The integration check asserts full-stack startup and service health plus
selected core workflows: Honcho migration ordering and failure propagation,
PostgreSQL writes/backup/restore, authenticated and unauthorized Forgejo API
access through fixture Traefik, network isolation, reboot persistence, and
candidate activation inside the guest. It does not prove every application
correct or verify real SSO enrollment or Pangolin's database-held routes.
Forgejo/GitLab runners, Hermes and its helper container, Tailscale, rclone
mounts, cloud credentials, and public ACME are excluded. The desktop, waypipe,
development-package, and Home Manager user-profile modules are also omitted.
Mail uses a local Mailpit sink; media uses synthetic audio fixtures.

Linkwarden and OmniRoute remain configured in the sandbox but are excluded from
automated unit and endpoint checks by user decision. Their startup correctness
is not covered by `just home-lab-test`.

For a historical upgrade rehearsal, apply the same reviewed sandbox module
to both the known-good and candidate service configurations **before either
is booted**. Verify test-only secrets, blocked egress, loopback forwards, and
disposable storage for both builds. Never run a historical revision's VM
recipe directly: it may predate these safeguards.

Create synthetic data under the isolated known-good build, stop that VM,
and boot the candidate against a copy of its disposable disk. Do not use
production keys or disks. Check application behavior and persisted values;
the automated same-version activation/reboot checks do not prove
compatibility with historical database schemas or safe database downgrades.

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
