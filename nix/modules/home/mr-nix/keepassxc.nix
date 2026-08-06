# KeePassXC as Freedesktop Secret Service provider for this user.
# Database exposure (which group is published) is still set per-db in the GUI.
{
  lib,
  pkgs,
  ...
}: {
  programs.keepassxc = {
    autostart = true;
    enable = true;
    settings = {
      FdoSecrets = {
        ConfirmAccessItem = true;
        ConfirmDeleteItem = true;
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
      };
    };
  };
  # Compete without GNOME Keyring / KWallet owning Secret Service.
  services.gnome-keyring.enable = lib.mkForce false;
  xdg = {
    autostart.enable = true;
    configFile."kwalletrc".text = ''
      [Wallet]
      Enabled=false
    '';
    # D-Bus activation default so clients start KeePassXC for org.freedesktop.secrets
    # (user XDG data takes precedence over system providers).
    dataFile."dbus-1/services/org.freedesktop.secrets.service".text = ''
      [D-BUS Service]
      Name=org.freedesktop.secrets
      Exec=${lib.getExe pkgs.keepassxc}
    '';
  };
}
