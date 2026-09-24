#!/usr/bin/env bash
set -euo pipefail

# Reproducible source-build smoke test for CI. The image must provide Rust
# 1.85+; Debian Bookworm's APT Cargo is intentionally rejected by install.sh.
IMAGE="${OWL_DOCKER_IMAGE:-rust:1.85-bookworm}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="${OWL_DOCKER_LIB_DIR:-$HOME/.owl/libs}"

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is required" >&2
  exit 1
fi
if [[ ! -d "$LIB_DIR" ]]; then
  echo "error: Mire libraries not found at $LIB_DIR" >&2
  echo "       set OWL_DOCKER_LIB_DIR to a checked-out library directory" >&2
  exit 1
fi

docker run --rm \
  -v "$ROOT_DIR:/src:ro" \
  -v "$LIB_DIR:/owl-libs:ro" \
  --tmpfs /src/avenys/bin:rw \
  --tmpfs /src/avenys/tests/log:rw \
  -w /src/avenys \
  "$IMAGE" \
  bash -lc '
    set -eu
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq clang-22 llvm-22 llvm-22-dev llvm-22-tools lld-22 pkg-config libssl-dev libsodium-dev zlib1g-dev libzstd-dev libarchive-dev
    test "$(llvm-config-22 --version | cut -d. -f1)" = 22
    export LLVM_CONFIG_PATH="$(command -v llvm-config-22)"
    cargo --version
    CARGO_TARGET_DIR=/tmp/avenys-target cargo test --release
    CARGO_TARGET_DIR=/tmp/avenys-target cargo build --release --bin mire
    cc -D_GNU_SOURCE -std=c11 -I/src/avenys/src/pal \
      /src/avenys/tests/pal_net_smoke.c \
      /src/avenys/src/pal/core/pal_core.c \
      /src/avenys/src/pal/core/pal_dispatch.c \
      /src/avenys/src/pal/linux/pal_linux.c \
      -pthread -ldl -lsodium -o /tmp/pal-net-smoke
    /tmp/pal-net-smoke
    /tmp/avenys-target/release/mire --version
    /tmp/avenys-target/release/mire test tests -j 8 --release --log --lib-dir /owl-libs --cache-dir /tmp/avenys-tests-cache
    cd /src/owl
    /tmp/avenys-target/release/mire build code/main.mire --config native/mire-config.toml --release --artifact bin --runtime minimal --lib-dir /owl-libs --cache-dir /tmp/owl-cache --output /tmp/owl
    /tmp/owl --version
    /tmp/owl --help >/tmp/owl-help.txt
    /tmp/owl check
  '
