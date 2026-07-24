{
  inputs,
  pkgs,
  ...
}: let
  pre-commit-check = import ./checks/pre-commit-check.nix {inherit inputs pkgs;};
  llm-packages =
    if inputs ? llm-agents
    then let
      llm-pkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
    in [
      llm-pkgs.antigravity-cli
      llm-pkgs.apm
      llm-pkgs.copilot-cli
      llm-pkgs.cursor-agent
      llm-pkgs.git-surgeon
      llm-pkgs.opencode
      llm-pkgs.rtk
    ]
    else [];
  nixos-cli-pkg =
    if inputs ? nixos-cli
    then [inputs.nixos-cli.packages.${pkgs.stdenv.hostPlatform.system}.default]
    else [];
  compose2nix-pkg =
    if inputs ? compose2nix
    then [inputs.compose2nix.packages.${pkgs.stdenv.hostPlatform.system}.default]
    else [];
in
  pkgs.mkShell {
    packages =
      llm-packages
      ++ nixos-cli-pkg
      ++ compose2nix-pkg
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
       git-agecrypt init
    '';
  }
