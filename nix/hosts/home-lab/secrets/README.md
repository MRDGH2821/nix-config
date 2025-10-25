# Secrets

## SOPS

Use the following command to create secrets:

```sh
sops file.yaml
```

## git-agecrypt

Use the following command to see file in encrypted form:

```sh
git cat-file -p HEAD:nix/hosts/home-lab/secrets/agecrypt/<file>
```
