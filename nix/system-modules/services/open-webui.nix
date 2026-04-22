{lib, ...}: {
  services.open-webui = {
    enable = true;
    openFirewall = true;
    port = 8181;
  };
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "open-webui"
    ];
}
