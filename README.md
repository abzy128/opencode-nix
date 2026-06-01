# opencode-nix

Always up-to-date Nix flake for [opencode](https://github.com/anomalyco/opencode), the open source AI coding agent.

This flake packages upstream prebuilt GitHub release binaries and checks hourly for new opencode releases.

## Binary cache

Prebuilt packages are published to the `opencode-ai` Cachix cache.

Quick setup:

```bash
nix run nixpkgs#cachix -- use opencode-ai
```

Or configure Nix manually:

```nix
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://opencode-ai.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:NCHdD59X431o0gW7l8Ug9pgrAMQ8JemM1BycfDiRrNQ="
      "opencode-ai.cachix.org-1:yhawa6DoCVDM4RvKByhVlEnwOctSOSNcHPBAmtBO6CQ="
    ];
  };
}
```

For non-NixOS installs, add these lines to `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`:

```conf
extra-substituters = https://opencode-ai.cachix.org
extra-trusted-public-keys = opencode-ai.cachix.org-1:yhawa6DoCVDM4RvKByhVlEnwOctSOSNcHPBAmtBO6CQ=
```

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

### Maintainer setup

GitHub Actions pushes successful `main` builds to Cachix. Configure this repository secret:

- `CACHIX_AUTH_TOKEN` — Cachix auth token with write access to the `opencode-ai` cache

Recommended GitHub repository settings:

- Actions workflow permissions: **Read and write permissions**
- Enable: **Allow GitHub Actions to create and approve pull requests**
- Enable repository auto-merge if you want update PRs to merge automatically after checks pass

Manual CI triggers:

```bash
gh workflow run build.yml
gh workflow run update.yml
# optionally test a specific release
gh workflow run update.yml -f version=1.15.13
```

The package wrapper disables opencode's self-updater with `OPENCODE_DISABLE_AUTOUPDATE=1` and provides `ripgrep` on `PATH`.

## Acknowledgements

Inspired by [sadjow/codex-cli-nix](https://github.com/sadjow/codex-cli-nix)
