# KeePassXC as the Freedesktop Secret Service (org.freedesktop.secrets)
# provider for this user. Opt-in: import this module for the account that
# should use KeePassXC as its keyring.
#
# Database exposure (which group is published over the Secret Service) is
# still configured per-database in the KeePassXC GUI.
{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.keepassxc = {
    autostart = true;
    enable = true;
    settings = {
      Browser = {
        AllowExpiredCredentials = true;
        CustomProxyLocation = "";
        Enabled = true;
        SearchInAllDatabases = true;
      };
      FdoSecrets = {
        ConfirmAccessItem = false;
        ConfirmDeleteItem = false;
        Enabled = true;
        ShowNotification = true;
        UnlockBeforeSearch = true;
      };
      GUI = {
        LaunchAtStartup = true;
        MinimizeOnClose = true;
        MinimizeOnStartup = true;
        MinimizeToTray = true;
        ShowTrayIcon = true;
        TrayIconAppearance = "colorful";
      };
      General = {
        BackupBeforeSave = true;
        BackupFilePathPattern = "./Bkp/{DB_FILENAME}.old.kdbx";
        ConfigVersion = 2;
        MinimizeAfterUnlock = true;
        NumberOfRememberedLastDatabases = 7;
      };
      SSHAgent.Enabled = true;
      Security = {
        IconDownloadFallback = true;
        LockDatabaseIdle = false;
        NoConfirmMoveEntryToRecycleBin = false;
      };
    };
  };
  # Don't let GNOME Keyring / KWallet own org.freedesktop.secrets.
  services.gnome-keyring.enable = lib.mkForce false;
  xdg = {
    autostart.enable = true;
    # KWallet off (KDE Secret Service backend).
    configFile."kwalletrc".text = ''
      [Wallet]
      Enabled=false
    '';
    # D-Bus activation default: clients that ask for org.freedesktop.secrets
    # start KeePassXC. User XDG data takes precedence over system providers.
    dataFile."dbus-1/services/org.freedesktop.secrets.service".text = ''
      [D-BUS Service]
      Name=org.freedesktop.secrets
      Exec=${lib.getExe pkgs.keepassxc}
    '';
  };
  # On non-NixOS (Fedora, …) `services.gnome-keyring.enable` is inert — the
  # daemon is launched by the session / PAM and would grab the Secret Service
  # name before KeePassXC. Shadow its secrets-component autostart so D-Bus
  # activation reaches KeePassXC instead. The ssh/pkcs11 components are
  # unaffected (separate .desktop files).
  xdg.configFile."autostart/gnome-keyring-secrets.desktop" =
    lib.mkIf config.targets.genericLinux.enable
    {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Secret Storage Service (disabled: KeePassXC provides it)
        Exec=true
        Hidden=true
        X-GNOME-Autostart-enabled=false
        NoDisplay=true
      '';
    };
}
