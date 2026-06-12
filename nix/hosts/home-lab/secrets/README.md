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

Use the following command to see file in encrypted form:

```sh
git cat-file -p HEAD:nix/hosts/home-lab/secrets/agecrypt/<file>
```
