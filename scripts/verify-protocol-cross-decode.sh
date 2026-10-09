#!/bin/sh
set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
owl_directory=$(CDPATH= cd -- "$script_directory/.." && pwd)
avenys_directory=$(CDPATH= cd -- "$owl_directory/../avenys" && pwd)

: "${MIRE_LIB_DIR:?Set MIRE_LIB_DIR to the pinned Mire library directory}"
mire_binary=${MIRE_BIN:-mire}
exchange_directory=$(mktemp -d "$owl_directory/tests/.protocol-cross-decode.XXXXXX")
relative_exchange_directory=${exchange_directory#"$owl_directory"/}
trap 'rm -rf "$exchange_directory"' EXIT HUP INT TERM

cargo run --locked --release -j 2 \
    --manifest-path "$avenys_directory/Cargo.toml" \
    --example protocol_cross_decode -- emit "$exchange_directory"

cd "$owl_directory"
OWL_PROTOCOL_CROSS_DECODE_DIR="$relative_exchange_directory" \
    "$mire_binary" test tests/protocol_wire.mire -j 1 --release \
    --lib-dir "$MIRE_LIB_DIR" \
    --cache-dir "$exchange_directory/mire-cache"

cargo run --locked --release -j 2 \
    --manifest-path "$avenys_directory/Cargo.toml" \
    --example protocol_cross_decode -- verify "$exchange_directory"
