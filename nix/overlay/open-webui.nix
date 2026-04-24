final: prev: let
  version = "0.9.1";
  src = final.fetchFromGitHub {
    owner = "open-webui";
    repo = "open-webui";
    tag = "v${version}";
    hash = "sha256-INUxpLGN+Jn2oYggA9kkp1zGY+LPQNXuRop4DaOi9Ps=";
  };

  frontend = prev.open-webui.passthru.frontend.overrideAttrs (
    oldAttrs: let
      pyodideVersion = "0.28.3";
      pyodide = final.fetchurl {
        hash = "sha256-fcqubT8VmGoJ8PnmxHE6DA8kv/DJDHToWoFyPxvGCUA=";
        url = "https://github.com/pyodide/pyodide/releases/download/${pyodideVersion}/pyodide-${pyodideVersion}.tar.bz2";
      };
    in {
      inherit version src;
      npmDepsHash = final.lib.fakeHash;

      preBuild = ''
        tar xf ${pyodide} -C static/
      '';
    }
  );
in {
  open-webui = prev.open-webui.overrideAttrs (oldAttrs: {
    inherit version src;

    makeWrapperArgs = ["--set FRONTEND_BUILD_DIR ${frontend}/share/open-webui"];

    passthru =
      oldAttrs.passthru
      // {
        inherit frontend;
      };

    meta =
      oldAttrs.meta
      // {
        changelog = "https://github.com/open-webui/open-webui/blob/${src.tag}/CHANGELOG.md";
      };
  });
}
