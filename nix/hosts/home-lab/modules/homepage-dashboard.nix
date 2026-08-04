{
  config,
  flake,
  pkgs,
  ...
}: let
  mkUrl = flake.lib.mkUrl config.networking.baseDomain;
in {
  environment.systemPackages = with pkgs; [
    iputils
  ];
  # systemd.services.homepage-dashboard = {
  #   serviceConfig = {
  #     SupplementaryGroups = ["docker" "podman"];
  #   };
  # };

  services.homepage-dashboard = {
    allowedHosts = config.networking.baseDomain;
    bookmarks = [
      {
        Server = [
          {
            Pangolin = [
              {
                description = "Identity-Aware Tunneled Reverse Proxy Server with Dashboard UI.";
                href = mkUrl "pangolin" true;
                icon = "sh-pangolin";
              }
            ];
          }
          {
            Authentik = [
              {
                description = "Take control of your identity needs with a secure, flexible solution.";
                href = mkUrl "authentik" true;
                icon = "sh-authentik";
              }
            ];
          }
          {
            pgAdmin4 = [
              {
                description = "pgAdmin is the most popular and feature rich Open Source administration and development platform for PostgreSQL, the most advanced Open Source database in the world.";
                href = mkUrl "pgadmin" true;
                icon = "sh-pgadmin";
              }
            ];
          }
        ];
      }
    ];
    enable = true;
    environmentFiles = [config.sops.secrets.homepage-dashboard.path];
    listenPort = 7000;
    openFirewall = true;
    services = [
      {
        Tools = [
          {
            "Omni Tools" = {
              container = "omni-tools";
              description = "Boost your productivity with OmniTools, the ultimate toolkit for getting things done quickly! Access thousands of user-friendly utilities for editing images, text, lists, and data, all directly from your browser.";
              href = mkUrl "omni-tools" true;
              icon = "sh-omnitools";
            };
          }
          {
            "Bento PDF" = {
              container = "bentopdf";
              description = "The PDF Toolkit built for privacy.";
              href = mkUrl "pdf" true;
              icon = "sh-bentopdf";
            };
          }
          {
            Vert = {
              container = "vert";
              description = "The file converter you'll love.";
              href = mkUrl "vert" true;
              icon = "sh-vert";
            };
          }
        ];
      }
      {
        Media = [
          {
            Navidrome = {
              description = "Your Personal Streaming Service.";
              href = mkUrl "navidrome" true;
              icon = "sh-navidrome";
              widget = {
                salt = "{{HOMEPAGE_VAR_NAVIDROME_SALT}}";
                token = "{{HOMEPAGE_VAR_NAVIDROME_TOKEN}}";
                type = "navidrome";
                url = mkUrl "navidrome" true;
                user = "{{HOMEPAGE_VAR_NAVIDROME_USER}}";
              };
            };
          }
          {
            Linkwarden = {
              description = "Linkwarden helps you collect, read, annotate, and fully preserve what matters, all in one place.";
              href = mkUrl "linkwarden" true;
              icon = "sh-linkwarden";
              widget = {
                key = "{{HOMEPAGE_VAR_LINKWARDEN_KEY}}";
                type = "linkwarden";
                url = mkUrl "linkwarden" true;
              };
            };
          }
          {
            Peertube = {
              description = "Videos sharing & live streaming on free open source software PeerTube! No ads, no tracking, no spam.";
              href = mkUrl "peertube" true;
              icon = "sh-peertube";
            };
          }
        ];
      }
      {
        Dev = [
          {
            Forgejo = {
              description = "Your Personal Streaming Service.";
              href = mkUrl "git" true;
              icon = "sh-forgejo";
              widget = {
                key = "{{HOMEPAGE_VAR_FORGEJO_KEY}}";
                type = "gitea";
                url = mkUrl "git" true;
              };
            };
          }
        ];
      }
      {
        Office = [
          {
            Nextcloud = {
              description = "Nextcloud is a safe home for all your data. Access and share your files, calendars, contacts, mail & more from any device, on your terms.";
              href = mkUrl "nc" true;
              icon = "sh-nextcloud";
            };
          }
        ];
      }
    ];
    settings = {
      connectivityCheck = true;
      layout = {
        Media.columns = 3;
        Tools.columns = 3;
      };
      title = "Home Lab";
    };
    widgets = [
      {
        datetime.format = {
          dateStyle = "long";
          timeStyle = "long";
        };
      }
      {
        resources = {
          cpu = true;
          disk = "/";
          memory = true;
        };
      }
      {
        search = {
          provider = "duckduckgo";
          target = "_blank";
        };
      }
    ];
  };
}
