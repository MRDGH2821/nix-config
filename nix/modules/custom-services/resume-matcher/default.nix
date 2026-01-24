{lib, ...}: let
  autoImportLib = import ../../../mylib/auto-import.nix {inherit lib;};
in {
  imports = autoImportLib.autoImportModules ./.;

  services.resume-matcher = {
    enable = true;
    backend.environmentFile = "/run/secrets/resume-matcher-backend.env";
    frontend.environmentFile = "/run/secrets/resume-matcher-frontend.env";
    backend.extraEnv = {
      LLM_PROVIDER = "openai";
      LLM_MODEL = "gpt-4o-mini";
    };
  };
}
