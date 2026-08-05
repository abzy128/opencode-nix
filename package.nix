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
  version = "1.18.14";

  platformMap = {
    "x86_64-linux" = {
      asset = "opencode-linux-x64.tar.gz";
      hash = "0wh5jxzd56p850w5a9kkzm03g9gjsc9y4mcfji9zmyzb5ax80fgj";
    };
    "aarch64-linux" = {
      asset = "opencode-linux-arm64.tar.gz";
      hash = "0bb0y5kp99kxfw176imv2g6lkvxv2q0a8w69v1cj804042mfgv97";
    };
    "x86_64-darwin" = {
      asset = "opencode-darwin-x64.zip";
      hash = "09c9qhj1z1pv0ixs74lrkbwya8wv5c6rj5l4nd7pmkllj2dfkckq";
    };
    "aarch64-darwin" = {
      asset = "opencode-darwin-arm64.zip";
      hash = "149j5vaf4lwq7i6vvbij4ip54fj5mhkvsyx8229fp1lhcjxjb0dd";
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
