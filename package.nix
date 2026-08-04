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
  version = "1.18.12";

  platformMap = {
    "x86_64-linux" = {
      asset = "opencode-linux-x64.tar.gz";
      hash = "0lhljq3p59x2pqhy17jzavdgq088df8pvdjkafzlzc06cdq3nbks";
    };
    "aarch64-linux" = {
      asset = "opencode-linux-arm64.tar.gz";
      hash = "1l1ac8x0ffw61h3bgczgjk76v6qar43xpkpabz5hmqbsgcawbfc2";
    };
    "x86_64-darwin" = {
      asset = "opencode-darwin-x64.zip";
      hash = "1zv40gpnlhdh9whlknznhxw1zn544y94p4ylaxyrpdqkhy0nmvvs";
    };
    "aarch64-darwin" = {
      asset = "opencode-darwin-arm64.zip";
      hash = "1qbq74c1cyp8137b0wh0cnb41530mdzhfh14fhb99i0gs8nl26da";
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
