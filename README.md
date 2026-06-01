# opencode-nix

Always up-to-date Nix flake for [opencode](https://github.com/anomalyco/opencode), the open source AI coding agent.

This flake packages upstream prebuilt GitHub release binaries and checks hourly for new opencode releases.

## Usage

```bash
nix run github:abzy128/opencode-nix
```

Install into your profile:

```bash
nix profile install github:abzy128/opencode-nix
```

Use from another flake:

```nix
{
  inputs.opencode-nix.url = "github:abzy128/opencode-nix";

  outputs = { nixpkgs, opencode-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ opencode-nix.packages.${system}.default ];
      };
    };
}
```

## Supported platforms

- `x86_64-linux` → `opencode-linux-x64.tar.gz` AVX2 build
- `aarch64-linux` → `opencode-linux-arm64.tar.gz`
- `x86_64-darwin` → `opencode-darwin-x64.zip` AVX2 build
- `aarch64-darwin` → `opencode-darwin-arm64.zip`

Baseline x64 packages are intentionally not used by default. A separate `opencode-baseline` package can be added later if needed.

## Development

```bash
nix build
./result/bin/opencode --version

./scripts/update.sh --check
./scripts/update.sh --version 1.15.13
```

The package wrapper disables opencode's self-updater with `OPENCODE_DISABLE_AUTOUPDATE=1` and provides `ripgrep` on `PATH`.

## Acknowledgements

Inspired by [sadjow/codex-cli-nix](https://github.com/sadjow/codex-cli-nix)
