# Secrets

## SOPS

Use the following command to create secrets:

```sh
sops file.yaml
```

### Hermes Agent

Provider keys live in `hermes.env` (dotenv, encrypted with SOPS like the other `*.env` files). After editing, `container@hermes-agent.service` is restarted via `sops.secrets.hermes-env.restartUnits`.

## git-agecrypt

Use the following command to see file in encrypted form:

```sh
git cat-file -p HEAD:nix/hosts/home-lab/secrets/agecrypt/<file>
```
