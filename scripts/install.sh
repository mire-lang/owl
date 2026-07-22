#!/usr/bin/env bash
set -euo pipefail

# Owl & Mire installer
# Builds both from source: mire (Rust) → owl (Mire compiled by mire)

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="${BIN_DIR:-$PREFIX/bin}"
BUILD_DIR="${BUILD_DIR:-$(mktemp -d)}"
KEEP_BUILD="${KEEP_BUILD:-0}"

OWL_REPO="https://github.com/mire-lang/owl.git"
MIRE_REPO="https://github.com/mire-lang/Avenys-rust.git"
LIBS_REPO="https://github.com/mire-lang/libs.git"

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
  mkdir -p "$owl_home/libs" "$owl_home/tmp"

  if [[ ! -f "$owl_home/config.toml" ]]; then
    cat > "$owl_home/config.toml" << 'CONFIG'
[owl]
version = "1.0.0"

[libs]
path = "$HOME/.owl/libs"

[download]
timeout = 30
retry = 3
CONFIG
  fi
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
  echo "==> fetching kioto standard library..."

  if [[ -d "$dst" ]]; then
    git -C "$dst" pull --ff-only
  else
    git clone --depth 1 "$LIBS_REPO" "$dst"
  fi

  # Symlink so ../kioto resolves from the owl project root
  ln -sfn "$dst/kioto" "$1/kioto"
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

  (cd "$src" && "$mire" build --release --owl-home "$owl_home" -o "$src/owl" 2>&1)

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
