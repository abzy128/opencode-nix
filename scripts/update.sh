#!/usr/bin/env bash
set -euo pipefail

readonly GITHUB_REPO="anomalyco/opencode"
readonly RELEASE_BASE="https://github.com/${GITHUB_REPO}/releases/download"
readonly ASSETS=(
  "opencode-linux-x64.tar.gz"
  "opencode-linux-arm64.tar.gz"
  "opencode-darwin-x64.zip"
  "opencode-darwin-arm64.zip"
)

log() { echo "[INFO] $*"; }
err() { echo "[ERROR] $*" >&2; }

ensure_root() {
  if [ ! -f flake.nix ] || [ ! -f package.nix ]; then
    err "Run from repository root"
    exit 1
  fi
}

ensure_tools() {
  command -v curl >/dev/null || { err "curl is required"; exit 1; }
  command -v jq >/dev/null || { err "jq is required"; exit 1; }
  command -v nix >/dev/null || { err "nix is required"; exit 1; }
  command -v nix-prefetch-url >/dev/null || { err "nix-prefetch-url is required"; exit 1; }
}

current_version() {
  sed -n 's/.*version = "\([^"]*\)".*/\1/p' package.nix | head -1
}

latest_version() {
  local auth_header=()
  if [ -n "${GH_TOKEN:-}" ]; then
    auth_header=(-H "Authorization: Bearer ${GH_TOKEN}")
  fi
  curl -fsSL "${auth_header[@]}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" \
    | jq -r '.tag_name' \
    | sed 's/^v//'
}

set_version() {
  local version="$1"
  sed -i.bak "s/version = \".*\";/version = \"${version}\";/" package.nix
}

set_hash() {
  local asset="$1"
  local hash="$2"
  local tmp
  tmp=$(mktemp)
  awk -v asset="$asset" -v hash="$hash" '
    $0 ~ "asset = \\\"" asset "\\\"" { in_asset = 1 }
    in_asset && /hash = / { sub(/hash = "[^"]*"/, "hash = \"" hash "\""); in_asset = 0 }
    { print }
  ' package.nix > "$tmp"
  mv "$tmp" package.nix
}

prefetch_asset() {
  local version="$1"
  local asset="$2"
  nix-prefetch-url "${RELEASE_BASE}/v${version}/${asset}" 2>/dev/null | tail -1 | tr -d '\n'
}

update_to() {
  local version="$1"
  log "Updating to ${version}"
  set_version "$version"

  for asset in "${ASSETS[@]}"; do
    log "Prefetching ${asset}"
    hash=$(prefetch_asset "$version" "$asset")
    if [ -z "$hash" ]; then
      err "Failed to prefetch ${asset}"
      mv package.nix.bak package.nix
      exit 1
    fi
    log "${asset}: ${hash}"
    set_hash "$asset" "$hash"
  done

  rm -f package.nix.bak

  log "Updating flake.lock"
  nix flake update

  log "Verifying build"
  nix build .#opencode
  ./result/bin/opencode --version
}

usage() {
  cat <<EOF
Usage: $0 [--check] [--version VERSION]
EOF
}

main() {
  ensure_root
  ensure_tools

  local check=false
  local target=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --check) check=true; shift ;;
      --version) target="${2:-}"; shift 2 ;;
      --help) usage; exit 0 ;;
      *) err "Unknown argument: $1"; usage; exit 1 ;;
    esac
  done

  local current latest
  current=$(current_version)
  latest=${target:-$(latest_version)}

  log "Current version: ${current}"
  log "Latest version: ${latest}"

  if [ "$current" = "$latest" ]; then
    log "Already up to date"
    exit 0
  fi

  if [ "$check" = true ]; then
    log "Update available: ${current} -> ${latest}"
    exit 1
  fi

  update_to "$latest"
  git diff --stat package.nix flake.lock || true
}

main "$@"
