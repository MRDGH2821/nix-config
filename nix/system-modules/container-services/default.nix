{lib, ...}: let
  autoImportLib = import ../../mylib/auto-import.nix {inherit lib;};
in {
  imports = autoImportLib.autoImportFolders ./.;
  networking.firewall = {
    extraCommands = "
      iptables -I nixos-fw 1 -i br+ -j ACCEPT
    ";
    extraStopCommands = "
      iptables -D nixos-fw -i br+ -j ACCEPT
    ";
    trustedInterfaces = ["br+"];
  };
}
