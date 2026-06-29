{
  config,
  lib,
  pkgs,
  mylibFor,
  ...
}: let
  mylib = mylibFor {inherit pkgs lib config;};
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
    enable = true;
    settings = {
      title = "Home Lab";
      connectivityCheck = true;
      layout = {
        Tools = {
          columns = 3;
        };
        Media = {
          columns = 3;
        };
      };
    };
    environmentFiles = [config.sops.secrets.homepage-dashboard.path];
    openFirewall = true;
    listenPort = 7000;
    allowedHosts = config.networking.baseDomain;
    widgets = [
      {
        datetime = {
          format = {
            dateStyle = "long";
            timeStyle = "long";
          };
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
    services = [
      {
        Tools = [
          {
            "Omni Tools" = {
              description = "Boost your productivity with OmniTools, the ultimate toolkit for getting things done quickly! Access thousands of user-friendly utilities for editing images, text, lists, and data, all directly from your browser.";
              href = mylib.mkUrl "omni-tools" true;
              icon = "sh-omnitools";
              container = "omni-tools";
            };
          }
          {
            "Bento PDF" = {
              description = "The PDF Toolkit built for privacy.";
              icon = "sh-bentopdf";
              href = mylib.mkUrl "pdf" true;
              container = "bentopdf";
            };
          }
          {
            Vert = {
              description = "The file converter you'll love.";
              icon = "sh-vert";
              href = mylib.mkUrl "vert" true;
              container = "vert";
            };
          }
        ];
      }
      {
        Media = [
          {
            Navidrome = {
              description = "Your Personal Streaming Service.";
              href = mylib.mkUrl "navidrome" true;
              icon = "sh-navidrome";
              widget = {
                type = "navidrome";
                url = mylib.mkUrl "navidrome" true;
                user = "{{HOMEPAGE_VAR_NAVIDROME_USER}}";
                token = "{{HOMEPAGE_VAR_NAVIDROME_TOKEN}}";
                salt = "{{HOMEPAGE_VAR_NAVIDROME_SALT}}";
              };
            };
          }
          {
            Linkwarden = {
              description = "Linkwarden helps you collect, read, annotate, and fully preserve what matters, all in one place.";
              href = mylib.mkUrl "linkwarden" true;
              icon = "sh-linkwarden";
              widget = {
                type = "linkwarden";
                url = mylib.mkUrl "linkwarden" true;
                key = "{{HOMEPAGE_VAR_LINKWARDEN_KEY}}";
              };
            };
          }
          {
            Peertube = {
              description = "Videos sharing & live streaming on free open source software PeerTube! No ads, no tracking, no spam.";
              href = mylib.mkUrl "peertube" true;
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
              href = mylib.mkUrl "git" true;
              icon = "sh-forgejo";
              widget = {
                type = "gitea";
                url = mylib.mkUrl "git" true;
                key = "{{HOMEPAGE_VAR_FORGEJO_KEY}}";
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
              href = mylib.mkUrl "nc" true;
              icon = "sh-nextcloud";
            };
          }
        ];
      }
    ];
    bookmarks = [
      {
        Server = [
          {
            Pangolin = [
              {
                href = mylib.mkUrl "pangolin" true;
                icon = "sh-pangolin";
                description = "Identity-Aware Tunneled Reverse Proxy Server with Dashboard UI.";
              }
            ];
          }
          {
            Authentik = [
              {
                href = mylib.mkUrl "authentik" true;
                icon = "sh-authentik";
                description = "Take control of your identity needs with a secure, flexible solution.";
              }
            ];
          }
          {
            pgAdmin4 = [
              {
                href = mylib.mkUrl "pgadmin" true;
                icon = "sh-pgadmin";
                description = "pgAdmin is the most popular and feature rich Open Source administration and development platform for PostgreSQL, the most advanced Open Source database in the world.";
              }
            ];
          }
        ];
      }
    ];
  };
}
