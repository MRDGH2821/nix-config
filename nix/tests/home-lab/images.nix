# Public registry snapshots for the isolated x86_64 sandbox, never runtime pulls.
{pkgs}: let
  honcho = {
    archive = pkgs.dockerTools.pullImage {
      arch = "amd64";
      finalImageTag = "v3.1.0";
      imageDigest = honcho.digest;
      imageName = "ghcr.io/plastic-labs/honcho";
      os = "linux";
      # antipatterns: ignore FS01 — dockerTools.pullImage requires this argument name.
      sha256 = "sha256-qlbsbCi780W2TQPXxpxOGzuL17iy7fnKJ5+D/Pik0SI=";
    };
    digest = "sha256:b73a8015f9e3ee51525e5b5cb238a915aa47de5107593d81b892213322fa369d";
    image = "ghcr.io/plastic-labs/honcho:v3.1.0";
    imageId = "sha256:e01041eb86df5de4d9afcd0da4dfa4a7aca80c19c4df62fcf3e81dc065bf520b";
  };
  omniroute = {
    archive = pkgs.dockerTools.pullImage {
      arch = "amd64";
      finalImageTag = "3.8.50-web";
      imageDigest = omniroute.digest;
      imageName = "ghcr.io/diegosouzapw/omniroute";
      os = "linux";
      # antipatterns: ignore FS01 — dockerTools.pullImage requires this argument name.
      sha256 = "sha256-yoKrtUuawnD7PrFhwfEVtovTJn8NJPXf7Ij6UaZtM2Y=";
    };
    digest = "sha256:0511348f97db9af067b90edfcd9508793c5ed74f56da7abc475624fb02a977df";
    image = "ghcr.io/diegosouzapw/omniroute:3.8.50-web";
    imageId = "sha256:094ed582a3ea9483b5c1fee1ba2b65529356963f31ab0b36c7ce2251107015f7";
  };
  omni-tools = {
    archive = pkgs.dockerTools.pullImage {
      arch = "amd64";
      finalImageTag = "0.6.0";
      imageDigest = omni-tools.digest;
      imageName = "iib0011/omni-tools";
      os = "linux";
      # antipatterns: ignore FS01 — dockerTools.pullImage requires this argument name.
      sha256 = "sha256-lN5/446OVzmA7Y3p91qCUl4R2z4alRBgUSRKrUneToQ=";
    };
    digest = "sha256:ceb5acc317daf387634f7f212cefe4722fd1243ad1cba74203f25254195b6c69";
    image = "iib0011/omni-tools:0.6.0";
    imageId = "sha256:63354e3f58079c611953724b79846527fdeaf0f7dc48cc7de1e826b1c4385565";
  };
  vert = {
    archive = pkgs.dockerTools.pullImage {
      arch = "amd64";
      finalImageTag = "latest";
      imageDigest = vert.digest;
      imageName = "ghcr.io/vert-sh/vert";
      os = "linux";
      # antipatterns: ignore FS01 — dockerTools.pullImage requires this argument name.
      sha256 = "sha256-KZQBn+0EPwSoChin0uZZlL3gRZh/r7EhNb7pRb9dKQg=";
    };
    digest = "sha256:51edb89e7c57197b0281ba8427fb27eea63730a3683b10d422061afab2708a49";
    image = "ghcr.io/vert-sh/vert:latest";
    imageId = "sha256:128b79433d12af32453d805352c8e9fcf778fa239682706a7bcdd1f8904659a4";
  };
in {
  inherit omni-tools vert;
  honcho-memory-api = honcho;
  honcho-memory-deriver = honcho;
  honcho-memory-migrate = honcho;
  omniroute-web = omniroute;
}
