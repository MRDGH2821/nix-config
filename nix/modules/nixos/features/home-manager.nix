# Defaults for Home Manager when Blueprint wires hosts/*/users.
{
  # Existing user files (e.g. hand-edited .zshrc, keepassxc.ini) should be
  # renamed rather than aborting activation on first declarative deploy.
  home-manager.backupFileExtension = "hm-backup";
}
