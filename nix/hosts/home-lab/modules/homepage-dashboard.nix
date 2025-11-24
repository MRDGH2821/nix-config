{config, ...}: let
  dmb = import ../../../mylib/domain-builder.nix {inherit config;};
in {
  services.homepage-dashboard = {
    enable = true;
    settings = {
      title = "Home Lab";
      connectivityCheck = true;
    };
    docker = {
      host = "localhost";
      port = 2375;
    };
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
              href = dmb.mkUrl "omni-tools" true;
              icon = "sh-OmniTools";
            };
          }
          {
            "Bento PDF" = {
              description = "The PDF Toolkit built for privacy.";
              icon = "sh-BentoPDF";
              href = dmb.mkUrl "pdf" true;
            };
          }
        ];
      }
    ];
  };
}
