# TEST ONLY: credentials, age key and TLS private key here are deliberately public.
# Import only from vmVariant or a NixOS test node, never the production host.
{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  images = import ./images.nix {inherit pkgs;};
  uniqueImages = lib.unique (builtins.attrValues images);
  secretNames = [
    "acme"
    "authentik"
    "baseDomain"
    "duckDnsToken"
    "dummyPassword"
    "fjr-runner-token"
    "glr-an"
    "hermes-env"
    "homepage-dashboard"
    "honcho-memory"
    "letsEncryptEmail"
    "linkwarden"
    "omniroute"
    "pangolin"
    "rclone"
    "searxng"
    "smtpEmail"
    "smtpPassword"
    "wireless"
  ];
  tiktokenUrl = "https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken";
  tiktokenCacheFile = builtins.hashString "sha1" tiktokenUrl;
  tiktokenEncoding = pkgs.fetchurl {
    hash = "sha256-RGqVOMtsNI41FhINfAiwn1fDZJXirP/+WaW/iwz7Gi0=";
    url = tiktokenUrl;
  };
  tiktokenCache = pkgs.runCommand "homelab-test-tiktoken-cache" {} ''
    install -Dm0444 ${tiktokenEncoding} "$out/${tiktokenCacheFile}"
  '';
  tiktokenCacheMount = "${tiktokenCache}:/tiktoken-cache:ro";
  tiktokenCacheEnvironment = "--env=TIKTOKEN_CACHE_DIR=/tiktoken-cache";
  honchoTiktokenContainers = [
    "honcho-memory-api"
    "honcho-memory-deriver"
    "honcho-memory-migrate"
  ];
  badger = pkgs.fetchFromGitHub {
    hash = "sha256-iHL2amAuiiufb9hlokRP14wHq2Ei2eQdUlYP4FmpS9o=";
    owner = "fosrl";
    repo = "badger";
    tag = "v1.2.0";
  };
  domains = map (prefix: "${prefix}.homelab.test") [
    "authentik"
    "git"
    "jellyfin"
    "linkwarden"
    "nextcloud"
    "omniroute"
    "pangolin"
    "pdf"
    "searxng"
  ];
in {
  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion =
            builtins.attrNames config.virtualisation.oci-containers.containers == builtins.attrNames images;
          message = "Every sandbox OCI container must have a pinned, offline image fixture.";
        }
        {
          assertion = lib.all (
            name: config.virtualisation.oci-containers.containers.${name}.image == images.${name}.image
          ) (builtins.attrNames images);
          message = "Update the pinned sandbox image fixture when changing a production image reference.";
        }
        {
          assertion = lib.all (secret: secret.sopsFile == ./fixtures/secrets.yaml) (
            builtins.attrValues config.sops.secrets
          );
          message = "The sandbox must not retain any production SOPS inputs.";
        }
        {
          assertion = let
            containers = config.virtualisation.oci-containers.containers;
          in
            lib.all (
              name:
                builtins.hasAttr name containers
                && lib.elem tiktokenCacheEnvironment containers.${name}.extraOptions
                && lib.elem tiktokenCacheMount containers.${name}.volumes
            )
            honchoTiktokenContainers;
          message = "Every sandbox Honcho container must mount the pinned tiktoken cache and set TIKTOKEN_CACHE_DIR.";
        }
      ];
      boot.loader = {
        efi.canTouchEfiVariables = lib.mkForce false;
        systemd-boot.enable = lib.mkForce false;
      };
      environment.etc."homelab-test/images.json".text = builtins.toJSON (
        lib.mapAttrs (_: image: {inherit (image) image digest imageId;}) images
      );
      # No enrollment, jobs on external repositories, paid calls or cloud data.
      my.rclone.mounts = lib.mkForce {};
      networking = {
        baseDomain = lib.mkForce "homelab.test";
        email = lib.mkForce "admin@homelab.test";
        hosts."127.0.0.1" = ["homelab.test"] ++ domains;
        networkmanager.enable = lib.mkForce false;
        smtp = {
          email = lib.mkForce "test@homelab.test";
          host = lib.mkForce "homelab.test";
          port = lib.mkForce 1025;
          username = lib.mkForce "test@homelab.test";
        };
        wireless.enable = lib.mkForce false;
      };
      persistent_storage = lib.mkForce "/var/lib/homelab-test";
      security = {
        acme.certs = lib.mkForce {};
        pam.services = {
          login.u2fAuth = lib.mkForce false;
          sudo.u2fAuth = lib.mkForce false;
        };
        pki.certificateFiles = [./fixtures/cert.pem];
      };
      services = {
        automatic-timezoned.enable = lib.mkForce false;
        forgejo-runner.enable = lib.mkForce false;
        gitlab-runner.enable = lib.mkForce false;
        hermes-agent = {
          container.enable = lib.mkForce false;
          enable = lib.mkForce false;
        };
        mailpit.instances.sandbox = {
          database = "sandbox.db";
          smtp = "127.0.0.1:1025";
          smtp-auth-accept-any = true;
          smtp-auth-allow-insecure = true;
          smtp-tls-cert = "${./fixtures/cert.pem}";
          smtp-tls-key = "${./fixtures/public-tls-key.pem}";
        };
        openssh.settings = {
          PasswordAuthentication = lib.mkForce true;
          PermitRootLogin = lib.mkForce "no";
        };
        pangolin.settings.domains.domain1 = {
          cert_resolver = lib.mkForce "";
          prefer_wildcard_cert = lib.mkForce false;
        };
        # pgAdmin's email validator rejects the reserved .test domain.
        pgadmin.initialEmail = lib.mkForce "admin@example.org";
        tailscale.enable = lib.mkForce false;
        traefik = {
          dynamicConfigOptions = {
            http = {
              # Fixture only: production Pangolin routes live in its database.
              routers =
                lib.genAttrs
                [
                  "next-router"
                  "api-router"
                  "ws-router"
                  "int-api-router"
                ]
                (_: {
                  tls.certResolver = lib.mkForce "";
                })
                // {
                  homelab-test-forgejo = {
                    entryPoints = ["websecure"];
                    rule = "Host(`git.homelab.test`)";
                    service = "homelab-test-forgejo";
                    tls = {};
                  };
                };
              services.homelab-test-forgejo.loadBalancer.servers = [
                # antipatterns: ignore FS03 — fixture route stays inside the guest.
                {url = "http://127.0.0.1:4000";}
              ];
            };
            tls = {
              certificates = [
                {
                  certFile = "${./fixtures/cert.pem}";
                  keyFile = "${./fixtures/public-tls-key.pem}";
                }
              ];
              stores.default.defaultCertificate = {
                certFile = "${./fixtures/cert.pem}";
                keyFile = "${./fixtures/public-tls-key.pem}";
              };
            };
          };
          # Local plugin mode avoids Traefik's startup download, not Pangolin auth.
          staticConfigOptions = {
            # Unlike resolver/plugin maps, this TLS struct has file:"allowEmpty".
            entryPoints.websecure.http.tls = lib.mkForce {};
            experimental.localPlugins.badger.moduleName = "github.com/fosrl/badger";
          };
        };
      };
      sops = {
        age = {
          generateKey = lib.mkForce false;
          keyFile = lib.mkForce "/run/homelab-test-age-key.txt";
          sshKeyPaths = lib.mkForce [];
        };
        defaultSopsFile = lib.mkForce ./fixtures/secrets.yaml;
        gnupg.sshKeyPaths = lib.mkForce [];
        # Override only ciphertext source/format/key: keep owners and templates.
        secrets = lib.genAttrs secretNames (name: {
          format = lib.mkForce "yaml";
          key = lib.mkForce name;
          sopsFile = lib.mkForce ./fixtures/secrets.yaml;
        });
      };
      swapDevices = lib.mkForce [];
      system.activationScripts = {
        homelab-test-age-key = {
          deps = ["specialfs"];
          supportsDryActivation = true;
          text = ''
            ${lib.getExe' pkgs.coreutils "install"} -m 0400 -o 0 -g 0 ${./fixtures/public-age-key.txt} ${lib.escapeShellArg config.sops.age.keyFile}
          '';
        };
        # SOPS activation precedes systemd; its script needs an explicit dependency.
        setupSecrets.deps = lib.mkIf (!config.sops.useSystemdActivation) ["homelab-test-age-key"];
      };
      systemd = {
        services =
          lib.mapAttrs' (
            _: container:
              lib.nameValuePair container.serviceName {
                after = ["homelab-test-images.service"];
                requires = ["homelab-test-images.service"];
              }
          )
          config.virtualisation.oci-containers.containers
          // {
            homelab-test-images = {
              # Podman is daemonless; its CLI needs tmpfiles, not podman.service.
              after = ["systemd-tmpfiles-setup.service"];
              description = "Load and verify pinned offline sandbox images";
              path = [config.virtualisation.podman.package];
              script =
                lib.concatMapStringsSep "\n" (image: ''
                  expected_id=${lib.escapeShellArg (lib.removePrefix "sha256:" image.imageId)}
                  actual_id="$(podman image inspect --format '{{.Id}}' ${lib.escapeShellArg image.image} 2>/dev/null)" || actual_id=""
                  if [ "''${actual_id#sha256:}" != "$expected_id" ]; then
                    podman load --input ${lib.escapeShellArg (toString image.archive)}
                    actual_id="$(podman image inspect --format '{{.Id}}' ${lib.escapeShellArg image.image})"
                  fi
                  if [ "''${actual_id#sha256:}" != "$expected_id" ]; then
                    echo ${lib.escapeShellArg "Pinned sandbox image ID mismatch for ${image.image}:"} "$actual_id (expected $expected_id)" >&2
                    exit 1
                  fi
                '')
                uniqueImages;
              serviceConfig = {
                RemainAfterExit = true;
                # Preserve the generated OCI preStart's allowance for large loads.
                TimeoutStartSec = 0;
                Type = "oneshot";
              };
              unitConfig.RequiresMountsFor = config.virtualisation.containers.storage.settings.storage.graphroot;
            };
            traefik = {
              # Yaegi resolves this source under its working directory.
              # antipatterns: ignore MOD03 — Traefik requires this fixed source path.
              preStart = ''
                mkdir -p plugins-local/src/github.com/fosrl
                ln -sfn ${badger} plugins-local/src/github.com/fosrl/badger
              '';
            };
          };
        tmpfiles.rules = [
          "d /var/lib/homelab-test 0755 root root -"
          "d /mnt/rclone/jellyfin/Music 0755 jellyfin jellyfin -"
          "d /mnt/rclone/jellyfin/Kirtans 0755 jellyfin jellyfin -"
          "C /mnt/rclone/jellyfin/Music/test-tone.wav 0444 jellyfin jellyfin - ${./fixtures/test-tone.wav}"
        ];
      };
      users.users = {
        mr-nix = {
          initialPassword = lib.mkForce "vm";
          openssh.authorizedKeys.keys = lib.mkForce [];
        };
        root = {
          initialPassword = lib.mkForce "vm";
          openssh.authorizedKeys.keys = lib.mkForce [];
        };
        system-recovery.openssh.authorizedKeys.keys = lib.mkForce [];
      };
      virtualisation = {
        cores = lib.mkDefault 4;
        diskSize = lib.mkDefault 30720;
        # Concurrent real apps, PostgreSQL and six OCI units (Omniroute is 5 GiB).
        memorySize = lib.mkDefault 12288;
        oci-containers.containers =
          lib.mapAttrs (
            name: _:
              {
                imageFile = lib.mkForce null;
                pull = lib.mkForce "never";
              }
              // lib.optionalAttrs (lib.elem name honchoTiktokenContainers) {
                extraOptions = lib.mkAfter [tiktokenCacheEnvironment];
                volumes = lib.mkAfter [tiktokenCacheMount];
              }
          )
          images;
        restrictNetwork = lib.mkForce true;
      };
    }
    # Interactive profiles add desktop/dev packages, not server coverage.
    (lib.optionalAttrs (options ? home-manager) {
      home-manager.users = lib.mkForce {};
    })
  ];
  disabledModules = [
    ../../hosts/home-lab/modules/desktop.nix
    ../../hosts/home-lab/modules/waypipe.nix
    ../../modules/nixos/features/dev-packages.nix
  ];
  # Drop disabled maps after merging; Traefik rejects them as standalone tables.
  options.services.traefik.staticConfigOptions = lib.mkOption {
    apply = settings:
      removeAttrs settings ["certificatesResolvers"]
      // {
        experimental = removeAttrs settings.experimental ["plugins"];
      };
  };
}
