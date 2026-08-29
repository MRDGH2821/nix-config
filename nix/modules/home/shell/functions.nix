# Shell functions ported verbatim from the chezmoi
# files/.chezmoitemplates/shell-scripts/shell_aliases.sh. Placed after the
# zsh.nix lib.mkOrder 550 block so `line` (used by the others) is defined.
# The duplicate `touchfile` that used to live in zsh.nix is now owned here.
{lib, ...}: {
  programs.zsh.initContent = lib.mkOrder 600 ''
    line() {
      printf '%*s\n' "''${COLUMNS:-$(tput cols)}" ''' | tr ' ' '-'
    }

    rmedirs() {
      local dir="''${1:-.}"
      local answer

      if [[ ! -d "''${dir}" ]]; then
        echo "Error: ''\'''${dir}' is not a valid directory."
        return 1
      fi

      echo "Dry run: empty directories that would be removed:"
      line
      find "''${dir}" -mindepth 1 -depth -type d -empty -print
      line

      printf "Remove these empty directories? [y/N]: "
      read -r answer

      case "''${answer}" in
        [yY] | [yY][eE][sS])
          echo "Deleting..."

          find "''${dir}" -mindepth 1 -depth -type d -empty -delete
          echo "Done."
          ;;
        *)
          echo "Aborted."
          ;;
      esac
    }

    touchfile() {
      mkdir -p "$(dirname "$1")" && touch "$1" && echo "$1"
    }

    export-gh() {
      local token

      if ! command -v gh >/dev/null 2>&1; then
        echo "Error: 'gh' is not installed." >&2
        return 1
      fi

      if ! token="$(gh auth token)"; then
        echo "Error: failed to get GitHub token (are you logged in? try 'gh auth login')." >&2
        return 1
      fi

      export GITHUB_TOKEN="''${token}"
      echo "GITHUB_TOKEN exported."
    }

    export-glab() {
      local token

      if ! command -v glab >/dev/null 2>&1; then
        echo "Error: 'glab' is not installed." >&2
        return 1
      fi

      # glab has no 'auth token' subcommand; parse the token off the
      # "Token ...: <value>" line printed by 'auth status --show-token'.
      token="$(glab auth status --show-token 2>&1 | sed -n 's/.*[Tt]oken.*: \([^[:space:]]*\)$/\1/p' | head -n 1)"

      if [[ -z "''${token}" || "''${token}" == *'*'* ]]; then
        echo "Error: failed to get GitLab token (are you logged in? try 'glab auth login')." >&2
        return 1
      fi

      export GITLAB_TOKEN="''${token}"
      echo "GITLAB_TOKEN exported."
    }

    update-repo() {
      local repo_dir="''${1:-.}"

      line
      echo "→ Updating repo: $(basename "''${repo_dir}")"
      line

      # Git pull
      git -C "''${repo_dir}" pull

      # Copier template update
      if [[ -f "''${repo_dir}/.copier-answers.yml" ]] || [[ -f "''${repo_dir}/.copier-answers.yaml" ]]; then
        line
        echo "• Copier template..."
        (cd "''${repo_dir}" && (copier check-update -q || copier update))
      fi

      # Python dependencies (uv)
      if [[ -f "''${repo_dir}/uv.lock" ]]; then
        line
        echo "• Python dependencies (uv)..."
        (cd "''${repo_dir}" && uv-upx upgrade run)
      fi

      # Rust dependencies (cargo)
      if [[ -f "''${repo_dir}/Cargo.lock" ]]; then
        line
        echo "• Rust dependencies (cargo)..."
        (cd "''${repo_dir}" && cargo update)
      fi

      # JS/TS dependencies (bun)
      if [[ -f "''${repo_dir}/bun.lock" ]] || [[ -f "''${repo_dir}/bun.lockb" ]]; then
        line
        echo "• JS dependencies (bun)..."
        (cd "''${repo_dir}" && bun update)
      fi

      # Go dependencies
      if [[ -f "''${repo_dir}/go.sum" ]]; then
        line
        echo "• Go dependencies..."
        (cd "''${repo_dir}" && go get -u ./... && go mod tidy)
      fi

      # Nix flake updates
      if [[ -f "''${repo_dir}/flake.lock" ]]; then
        line
        echo "• Nix flake updates..."
        (cd "''${repo_dir}" && nix flake update)
      fi

      # Skills (agent skills update)
      if [[ -f "''${repo_dir}/skills-lock.json" ]]; then
        line
        echo "• Skills update..."
        (cd "''${repo_dir}" && bun x skills update -p -y)
      fi

      # Compose updater
      if command -v ccu >/dev/null 2>&1; then
        line
        echo "• Compose updater..."
        (cd "''${repo_dir}" && ccu -f -u)
      fi

      # GitHub Actions updater
      if [[ -d "''${repo_dir}/.github/workflows/" ]]; then
        line
        echo "• GitHub Actions updater..."
        (cd "''${repo_dir}" && bunx actions-up@latest -r)
      fi

      line
      echo "✓ Repo update complete"
      line
    }
  '';
}
