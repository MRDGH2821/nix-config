{
  inputs,
  pkgs,
  ...
}: let
  inherit (pkgs) lib;
  pre-commit-check = import ./checks/pre-commit-check.nix {inherit inputs pkgs;};
  sys = pkgs.stdenv.hostPlatform.system;
  optionalInput = name: f: lib.optionals (inputs ? ${name}) (f inputs.${name}.packages.${sys});
in
  pkgs.mkShell {
    packages =
      optionalInput "llm-agents" (p: [
        p.antigravity-cli
        p.apm
        p.copilot-cli
        p.cursor-agent
        p.git-surgeon
        p.opencode
        p.rtk
      ])
      ++ optionalInput "nixos-cli" (p: [p.default])
      ++ optionalInput "compose2nix" (p: [p.default])
      ++ [
        pkgs.nil
        pkgs.nixd
        pkgs.sops
        pkgs.just
        pkgs.just-lsp
        pkgs.git-agecrypt
      ];
    shellHook = ''
      ${pre-commit-check.shellHook}
      rtk init --opencode 
      rtk init -g --gemini 
      rtk init -g --copilot
      rtk init --agent cursor
      rtk init --agent antigravity
      rtk init --agent hermes
      ${pkgs.lib.getExe pkgs.git-agecrypt} init
      apm install
    '';
  }
