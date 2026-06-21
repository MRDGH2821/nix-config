{mylib, ...}: {
  imports = mylib.autoImportFolders ./.;
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
