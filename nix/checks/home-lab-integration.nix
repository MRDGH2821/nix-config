{
  flake,
  inputs,
  perSystem,
  pkgs,
  system,
  ...
}: let
  inherit (pkgs) lib;
  platforms = ["x86_64-linux"];
in
  # Blueprint filters checks by meta.platforms before evaluating the derivation.
  if system != "x86_64-linux"
  then {meta = {inherit platforms;};}
  else
    pkgs.testers.runNixOSTest {
      defaults.virtualisation = {
        forwardPorts = lib.mkForce [];
        # Service-only guests need no VGA; omitting it also avoids unused bochs DRM work.
        graphics = false;
        qemu.options = ["-vga none"];
        restrictNetwork = true;
      };
      globalTimeout = 3600;
      meta = {inherit platforms;};
      name = "home-lab-integration";
      node = {
        # The real hardware module declares hostPlatform; native pkgs must not make it read-only.
        pkgsReadOnly = false;
        specialArgs = {
          inherit flake inputs;
          hostName = "home-lab";
        };
      };
      nodes = {
        client = {nodes, ...}: {
          environment.systemPackages = [
            pkgs.curl
            pkgs.netcat-openbsd
            pkgs.postgresql_17
          ];
          security.pki = {
            inherit (nodes.server.security.pki) certificateFiles certificates;
          };
          virtualisation.memorySize = 512;
        };
        server = {config, ...}: {
          _module.args = {inherit perSystem;};
          environment.systemPackages = [
            config.services.forgejo.package
            config.services.postgresql.package
            pkgs.curl
            pkgs.gzip
            pkgs.netcat-openbsd
            pkgs.jq
          ];
          # The native framework already imports qemu-vm.nix; vmVariant is not a node.
          imports = [
            ../hosts/home-lab/configuration.nix
            ../tests/home-lab/sandbox.nix
            inputs.home-manager.nixosModules.default
          ];
          networking.hostName = lib.mkForce "server";
          # A distinct, prebuilt candidate exercises real guest activation, not a host profile.
          specialisation.integration-candidate.configuration.environment.etc."homelab-candidate".text = "candidate\n";
          # Keep the native driver's root login; the manual VM retains its console password.
          users.users.root.initialPassword = lib.mkOverride 40 null;
          virtualisation = {
            cores = 4;
            diskSize = 40960;
            memorySize = 12288;
          };
        };
      };
      testScript = {nodes, ...}: let
        cfg = nodes.server;
        settings = {
          backup = "${cfg.services.postgresqlBackup.location}/all.sql.gz";
          containers = builtins.attrNames cfg.virtualisation.oci-containers.containers;
          forgejo = {
            executable = lib.getExe cfg.services.forgejo.package;
            user = cfg.services.forgejo.user;
            work = cfg.services.forgejo.stateDir;
          };
          postgresqlPackage = toString cfg.services.postgresql.finalPackage;
          redisUnits = map (name: "redis${lib.optionalString (name != "") "-${name}"}.service") (
            builtins.attrNames cfg.services.redis.servers
          );
          searxEnabled = cfg.services.searx.enable;
          serverAddress = cfg.networking.primaryIPAddress;
        };
      in
        builtins.readFile ../tests/home-lab/integration.py
        + ''

          run(server, client, json.loads(${builtins.toJSON (builtins.toJSON settings)}), subtest)
        '';
    }
