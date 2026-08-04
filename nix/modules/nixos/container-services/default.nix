{flake, ...}: let
  lib = flake.inputs.nixpkgs.lib;
  auto = import ../../../lib/auto-import.nix {inherit lib;};
in {
  imports = auto.autoImportFolders ./.;
  networking.firewall = {
    extraCommands = "iptables -I nixos-fw 1 -i br+ -j ACCEPT";
    extraStopCommands = "iptables -D nixos-fw -i br+ -j ACCEPT";
    trustedInterfaces = ["br+"];
  };
}
