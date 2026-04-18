{config, ...}: {
  programs.openclaw = {
    enable = true;

    documents = ./documents;
    config = {
      gateway = {
        mode = "local";
        auth = {
          token = config.sops.secrets.openclawGatewayToken.path;
        };
      };
      agents.defaults = {
        model.primary = "ollama/llama3.21:b";
      };
    };
    bundledPlugins = {
      summarize.enable = true;
      peekaboo.enable = false;
    };
  };
}
