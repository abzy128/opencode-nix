{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, unzip
, cacert
, ripgrep
}:

let
  version = "1.17.3";

  platformMap = {
    "x86_64-linux" = {
      asset = "opencode-linux-x64.tar.gz";
      hash = "0z8a05rbvyrairzpll9l4acza5x3l0hpsffk3k56mx8z5j527gfl";
    };
    "aarch64-linux" = {
      asset = "opencode-linux-arm64.tar.gz";
      hash = "1r81i13a7kqsqawkgn0ppm23lrnygvj3qxzacsd6s7fmrrk8q6w6";
    };
    "x86_64-darwin" = {
      asset = "opencode-darwin-x64.zip";
      hash = "108gm4azh05rbvizlz8a83b7934f405vl88fh2l41r6ycyjngyiv";
    };
    "aarch64-darwin" = {
      asset = "opencode-darwin-arm64.zip";
      hash = "04zx20r14wrvci2crsmvvz1h779q73qf4m28smvwb4lfdpwli6dl";
    };
  };

  platform = platformMap.${stdenv.hostPlatform.system} or null;
in
assert platform != null || throw "opencode is not supported on ${stdenv.hostPlatform.system}";

stdenv.mkDerivation rec {
  pname = "opencode";
  inherit version;

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/${platform.asset}";
    sha256 = platform.hash;
  };

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  nativeBuildInputs = [ makeWrapper ]
    ++ lib.optional stdenv.isLinux autoPatchelfHook
    ++ lib.optional stdenv.isDarwin unzip;

  buildInputs = lib.optionals stdenv.isLinux [
    stdenv.cc.cc.lib
  ];

  unpackPhase = if stdenv.isDarwin then ''
    runHook preUnpack
    unzip -q $src
    runHook postUnpack
  '' else ''
    runHook preUnpack
    tar -xzf $src
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 opencode $out/bin/opencode

    wrapProgram $out/bin/opencode \
      --prefix PATH : ${lib.makeBinPath [ ripgrep ]} \
      --set OPENCODE_DISABLE_AUTOUPDATE 1 \
      --set SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt \
      --set NODE_EXTRA_CA_CERTS ${cacert}/etc/ssl/certs/ca-bundle.crt

    runHook postInstall
  '';

  meta = with lib; {
    description = "The open source AI coding agent";
    homepage = "https://opencode.ai/";
    license = licenses.mit;
    mainProgram = "opencode";
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  };
}
