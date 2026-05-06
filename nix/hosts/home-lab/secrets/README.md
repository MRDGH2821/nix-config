# Secrets

## SOPS

Use the following command to create secrets:

```sh
sops file.yaml
```

### Hermes Agent

Provider keys live in `hermes.env` (dotenv, encrypted with SOPS like the other `*.env` files). Enable the gateway API with `API_SERVER_ENABLED=true`; if you protect it with `API_SERVER_KEY`, the workspace cannot use `API_SERVER_KEY` as-is — Hermes Workspace reads `HERMES_API_TOKEN`. Set `HERMES_API_TOKEN` to the same value as `API_SERVER_KEY` in `hermes-workspace.env`. After editing `hermes.env`, `hermes-agent.service` is restarted via `sops.secrets.hermes-env.restartUnits`.

### Hermes Workspace

`hermes-workspace.env` (see `sops.secrets.hermes-workspace`) holds optional overrides such as `HERMES_PASSWORD` and `HERMES_API_TOKEN`. Nix injects `HERMES_API_URL` and `HERMES_DASHBOARD_URL` to `host.containers.internal` for the gateway (`:8642`) and dashboard (`:9119`). After editing secrets, `podman-hermes-workspace-hermes-workspace.service` restarts via `sops.secrets.hermes-workspace.restartUnits`.

## git-agecrypt

Use the following command to see file in encrypted form:

```sh
git cat-file -p HEAD:nix/hosts/home-lab/secrets/agecrypt/<file>
```
