# Secrets

## SOPS

Use the following command to create secrets:

```sh
sops file.yaml
```

### Hermes Agent

Provider keys live in `hermes.env` (dotenv, encrypted with SOPS like the other `*.env` files). Enable the gateway API with `API_SERVER_ENABLED=true` so the WebUI can reach scheduled jobs and gateway health endpoints. After editing `hermes.env`, `hermes-agent.service` is restarted via `sops.secrets.hermes-env.restartUnits`.

### Hermes WebUI

The WebUI container (`podman-hermes-webui.service`) shares the agent's `HERMES_HOME` at `${persistent_storage}/hermes-agent/.hermes`, mounts the Nix-built agent package at `current-package` for dependency install, and uses **host networking** so `HERMES_WEBUI_GATEWAY_BASE_URL` reaches the gateway on `http://127.0.0.1:8642`. The agent serves the dashboard on port `9119` via `HERMES_DASHBOARD_HOST` / `HERMES_DASHBOARD_PORT` in `hermes-agent.nix`. Chat UI listens on port `8787`. Optional remote access password: set `HERMES_WEBUI_PASSWORD` in the container `environment` block in `hermes-webui/default.nix` or add a SOPS-backed `environmentFiles` entry.

## git-agecrypt

Some Nix modules under `agecrypt/` are encrypted at rest in git using
[git-agecrypt](https://github.com/bartei/git-agecrypt). Plaintext stays in your
working tree; ciphertext is what gets committed and pushed.

Configuration lives in:

- `.gitattributes` — git clean/smudge filter for `agecrypt/**`
- `git-agecrypt.toml` — age public keys (recipients) per file path

### Decrypt files (one-time per clone)

1. Enter the dev shell (runs `git-agecrypt init` automatically):

   ```sh
   direnv allow # or: nix develop
   ```

2. Register your private key (stored locally in `.git/config`, never committed):

   ```sh
   # Native age identity
   git-agecrypt config add -i ~/.config/age/your-key.txt
   
   # Or an OpenSSH key (ed25519/RSA) if that was used as the recipient
   git-agecrypt config add -i ~/.ssh/id_ed25519
   ```

3. Verify the identity matches a configured recipient:

   ```sh
   git-agecrypt status
   ```

   A `✓` next to your identity means the key file exists and parses correctly.

4. Re-checkout to decrypt the working tree:

   ```sh
   git checkout -- nix/hosts/home-lab/secrets/agecrypt/
   ```

After setup, `git pull`, `git checkout`, and `git diff` handle encryption and
decryption transparently.

### Viewing file contents

| Goal                       | Command                                                            |
| -------------------------- | ------------------------------------------------------------------ |
| Plaintext in working tree  | Open the file normally (after identity + checkout)                 |
| Decrypted diff             | `git diff nix/hosts/home-lab/secrets/agecrypt/<file>`              |
| Decrypted view of one file | `git-agecrypt textconv nix/hosts/home-lab/secrets/agecrypt/<file>` |
| Ciphertext stored in git   | `git cat-file -p HEAD:nix/hosts/home-lab/secrets/agecrypt/<file>`  |

### Adding a new encrypted file

```sh
# Create the file, then register recipients for its path
git-agecrypt config add -r age1... -p nix/hosts/home-lab/secrets/agecrypt/new-file.nix
git add nix/hosts/home-lab/secrets/agecrypt/new-file.nix git-agecrypt.toml
git commit -m "feat(secrets): add encrypted new-file.nix"
```

Paths under `agecrypt/**` are already covered by `.gitattributes`.

### Troubleshooting

- **Files still show `age-encryption.org/v1` headers** — identity does not match
  any recipient in `git-agecrypt.toml`, or you have not re-checked out after
  adding the identity.
- **`git-agecrypt status` shows `⨯` on identity** — wrong path, permissions, or
  invalid key file.
- **No `git-agecrypt` command** — use `nix develop` or direnv in this repo.
