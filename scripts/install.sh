#!/usr/bin/env bash
set -euo pipefail

# Owl & Mire installer
# Builds both from source: mire (Rust) → owl (Mire compiled by mire)

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="${BIN_DIR:-$PREFIX/bin}"
BUILD_DIR="${BUILD_DIR:-$(mktemp -d)}"
KEEP_BUILD="${KEEP_BUILD:-0}"
YES="${OWL_INSTALL_YES:-0}"

OWL_REPO="${OWL_REPO:-https://github.com/Evelynx-Dev/owl.git}"
MIRE_REPO="${MIRE_REPO:-https://github.com/Evelynx-Dev/Avenys-rust.git}"
MIRE_LIB_REPO="${MIRE_LIB_REPO:-https://github.com/Evelynx-Dev/mire-lib.git}"
KIOTO_REPO="${KIOTO_REPO:-https://github.com/Evelynx-Dev/Kioto-1.git}"

OWL_BRANCH="main"
MIRE_BRANCH="main"

usage() {
  cat <<USAGE
Usage: install.sh [options]

Options:
  --prefix <path>      Install prefix (default: ~/.local)
  --bin-dir <path>     Binary directory (default: <prefix>/bin)
  --build-dir <path>   Build workspace (default: temp dir)
  --keep-build         Keep build directory after install
  --yes                Non-interactive dependency installation
  --check              Check host prerequisites without installing
  --mire-repo <url>    Avenys source repository
  --owl-repo <url>     Owl source repository
  --mire-lib-repo <url> Mire standard library repository
  --kioto-repo <url>   Kioto standard library repository
  -h, --help           Show this help
USAGE
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    echo "  install: $2" >&2
    exit 1
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prefix) PREFIX="$2"; BIN_DIR="$2/bin"; shift 2 ;;
      --bin-dir) BIN_DIR="$2"; shift 2 ;;
      --build-dir) BUILD_DIR="$2"; KEEP_BUILD=1; shift 2 ;;
      --keep-build) KEEP_BUILD=1; shift ;;
      --yes|-y) YES=1; shift ;;
      --check) CHECK_ONLY=1; shift ;;
      --mire-repo) MIRE_REPO="$2"; shift 2 ;;
      --owl-repo) OWL_REPO="$2"; shift 2 ;;
      --mire-lib-repo) MIRE_LIB_REPO="$2"; shift 2 ;;
      --kioto-repo) KIOTO_REPO="$2"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) echo "error: unknown option: $1" >&2; usage; exit 1 ;;
    esac
  done
}

cleanup() {
  if [[ "$KEEP_BUILD" != "1" && -n "${BUILD_DIR:-}" ]]; then
    rm -rf "$BUILD_DIR"
  fi
}

setup_owl_dirs() {
  local owl_home="$HOME/.owl"
  mkdir -p "$owl_home/libs" "$owl_home/reg" "$owl_home/cfg" \
    "$owl_home/cache" "$owl_home/cache/registry" "$owl_home/version" "$owl_home/tmp"

  if [[ ! -f "$owl_home/config.toml" ]]; then
    cat > "$owl_home/config.toml" <<CONFIG
[owl]
version = "1.0.0"

[libs]
path = "$owl_home/libs"

[registry]
path = "$owl_home/reg"

[download]
timeout = 30
retry = 3
CONFIG
  fi
}

detect_pkg_manager() {
  if command -v apt-get >/dev/null 2>&1; then echo apt
  elif command -v dnf >/dev/null 2>&1; then echo dnf
  elif command -v pacman >/dev/null 2>&1; then echo pacman
  elif command -v apk >/dev/null 2>&1; then echo apk
  elif command -v zypper >/dev/null 2>&1; then echo zypper
  else echo none
  fi
}

ensure_build_dependencies() {
  local missing="" pm
  for cmd in git cargo clang; do
    command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
  done
  if command -v cargo >/dev/null 2>&1; then
    local cargo_version cargo_major cargo_minor
    cargo_version="$(cargo --version | sed -n 's/^cargo \([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2/p')"
    cargo_major="${cargo_version%% *}"
    cargo_minor="${cargo_version##* }"
    if [[ -z "$cargo_version" || "$cargo_major" -lt 1 || ( "$cargo_major" == 1 && "$cargo_minor" -lt 85 ) ]]; then
      missing="$missing cargo>=1.85"
    fi
  fi
  local llvm_config=""
  if command -v llvm-config-22 >/dev/null 2>&1; then llvm_config="llvm-config-22";
  elif command -v llvm-config >/dev/null 2>&1; then llvm_config="llvm-config"; fi
  if [[ -z "$llvm_config" ]] || [[ "$("$llvm_config" --version 2>/dev/null | cut -d. -f1)" != "22" ]]; then
    missing="$missing llvm-22"
  fi
  command -v llc-22 >/dev/null 2>&1 || command -v llc >/dev/null 2>&1 || missing="$missing llc-22"
  command -v llvm-ar-22 >/dev/null 2>&1 || command -v llvm-ar >/dev/null 2>&1 || missing="$missing llvm-ar-22"
  command -v ld.lld-22 >/dev/null 2>&1 || command -v ld.lld >/dev/null 2>&1 || missing="$missing lld-22"
  command -v install >/dev/null 2>&1 || missing="$missing coreutils"
  command -v pkg-config >/dev/null 2>&1 || missing="$missing pkg-config"
  if command -v pkg-config >/dev/null 2>&1 && ! pkg-config --exists libarchive; then missing="$missing libarchive-dev"; fi
  if [[ -z "$missing" ]]; then return 0; fi

  pm="$(detect_pkg_manager)"
  echo "missing build dependencies:$missing"
  if [[ "$missing" == *"cargo>=1.85"* ]]; then
    echo "Avenys requires Rust/Cargo 1.85+ for the 2024 edition."
    echo "Install or select a current rustup toolchain, then rerun this script."
  fi
  if [[ "$CHECK_ONLY" == "1" || "$YES" != "1" ]]; then
    echo "install them with the package manager for this distribution, or rerun with --yes"
    [[ "$CHECK_ONLY" == "1" ]] && return 1
    return 0
  fi
  case "$pm" in
    apt) sudo apt-get update; sudo apt-get install -y git curl build-essential clang-22 llvm-22 llvm-22-dev llvm-22-tools lld-22 cargo pkg-config libssl-dev libsodium-dev zlib1g-dev libzstd-dev libarchive-dev ;;
    dnf) sudo dnf install -y git curl gcc gcc-c++ clang llvm llvm-devel lld cargo pkgconf-pkg-config openssl-devel libsodium-devel zlib-devel zstd-devel libarchive-devel ;;
    pacman) sudo pacman -Sy --needed --noconfirm git curl base-devel clang llvm lld rust openssl libsodium zlib zstd libarchive ;;
    apk) sudo apk add git curl build-base clang llvm llvm-dev lld cargo openssl-dev libsodium-dev zlib-dev zstd-dev libarchive-dev ;;
    zypper) sudo zypper install -y git curl gcc gcc-c++ clang llvm llvm-devel lld rust cargo libopenssl-devel libsodium-devel zlib-devel libzstd-devel libarchive-devel ;;
    *) echo "no supported package manager found; install:$missing" >&2; return 1 ;;
  esac
}

build_mire() {
  local src="$1/mire-src"
  echo ""
  echo "==> building mire compiler (Rust)..."

  if [[ -d "$src" ]]; then
    echo "    updating existing clone..."
    git -C "$src" pull --ff-only
  else
    git clone --depth 1 -b "$MIRE_BRANCH" "$MIRE_REPO" "$src"
  fi

  (cd "$src" && cargo build --release 2>&1)

  local binary="$src/target/release/mire"
  if [[ ! -f "$binary" ]]; then
    echo "error: mire binary not found at $binary" >&2
    exit 1
  fi

  echo "    mire built: $binary"
  MIRE_BIN="$binary"
}

setup_kioto() {
  local dst="$1/libs"
  echo ""
  echo "==> fetching Mire and Kioto standard libraries..."

  rm -rf "$dst/mire" "$dst/kioto"
  git clone --depth 1 "$MIRE_LIB_REPO" "$dst/mire"
  git clone --depth 1 "$KIOTO_REPO" "$dst/kioto"
}

build_owl() {
  local src="$1/owl"
  echo ""
  echo "==> building owl (with mire)..."

  if [[ -d "$src" ]]; then
    git -C "$src" pull --ff-only
  else
    git clone --depth 1 -b "$OWL_BRANCH" "$OWL_REPO" "$src"
  fi

  local mire="$MIRE_BIN"
  local owl_home="$1/libs"

  (cd "$src" && "$mire" build code/main.mire --config native/mire-config.toml \
    --release --artifact bin --runtime minimal --lib-dir "$owl_home" \
    --cache-dir "$src/bin/.cache" --output "$src/owl" 2>&1)

  local binary="$src/owl"
  if [[ ! -f "$binary" ]]; then
    echo "error: owl binary not found at $binary" >&2
    ls -la "$src/" >&2
    exit 1
  fi

  echo "    owl built: $binary"
  OWL_BIN="$binary"
}

install_binaries() {
  mkdir -p "$BIN_DIR"

  echo ""
  echo "==> installing..."

  install -m 0755 "$MIRE_BIN" "$BIN_DIR/mire"
  echo "    installed: $BIN_DIR/mire"

  install -m 0755 "$OWL_BIN" "$BIN_DIR/owl"
  echo "    installed: $BIN_DIR/owl"
}

main() {
  parse_args "$@"

  CHECK_ONLY="${CHECK_ONLY:-0}"
  ensure_build_dependencies
  [[ "$CHECK_ONLY" == "1" ]] && { echo "host prerequisites are available"; exit 0; }

  require_cmd git "git (https://git-scm.com)"
  require_cmd cargo "rust/cargo (https://rustup.rs)"
  require_cmd clang "clang (https://clang.llvm.org)"
  require_cmd install "(coreutils)"

  trap cleanup EXIT

  setup_owl_dirs

  build_mire "$BUILD_DIR"
  setup_kioto "$BUILD_DIR"
  build_owl "$BUILD_DIR"
  install_binaries

  echo ""
  echo "=== owl + mire installed ==="
  echo "  mire: $BIN_DIR/mire"
  echo "  owl:  $BIN_DIR/owl"
  echo ""
  "$BIN_DIR/mire" --version
  "$BIN_DIR/owl" info

  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
      echo ""
      echo "warning: $BIN_DIR is not in PATH"
      echo "add this to your shell profile:"
      echo "  export PATH=\"$BIN_DIR:\$PATH\""
      ;;
  esac
}

main "$@"
