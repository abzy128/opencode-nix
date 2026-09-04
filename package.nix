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
  version = "1.18.28";

  platformMap = {
    "x86_64-linux" = {
      asset = "opencode-linux-x64.tar.gz";
      hash = "1hy7zqsd5pwc2qr3g1vs6x4w2i19mz6i3p2shl9zvg8k3zxx1ba2";
    };
    "aarch64-linux" = {
      asset = "opencode-linux-arm64.tar.gz";
      hash = "15s4bg58g93hv43bjwr0nin3c123278cmk71vwncbk7fcyad7c6c";
    };
    "x86_64-darwin" = {
      asset = "opencode-darwin-x64.zip";
      hash = "1l2cdy0n48wxppy5041y0lbnix3z6zx2l7j09wxajckxqp2l6d4y";
    };
    "aarch64-darwin" = {
      asset = "opencode-darwin-arm64.zip";
      hash = "0iqgym2a7pwshvk1vv92r0s2wj921rxsf6v95c7i83bsb0sxlns0";
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
