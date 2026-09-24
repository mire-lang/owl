#!/usr/bin/env bash
set -euo pipefail

# Owl installer (auditable mode)
# Shows each operation and asks for confirmation before running.

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_SCRIPT="$SELF_DIR/install.sh"

if [[ ! -x "$BASE_SCRIPT" ]]; then
  echo "error: install.sh not found or not executable at: $BASE_SCRIPT" >&2
  exit 1
fi

printf 'Audit mode: commands will be shown before execution.\n\n'
printf '1) Show installer help\n'
"$BASE_SCRIPT" --help

echo
read -r -p "2) Continue with installation now? [y/N] " ans
case "$ans" in
  y|Y|yes|YES) ;;
  *) echo "aborted"; exit 0 ;;
esac

echo
printf '3) Running installer...\n\n'
set -x
"$BASE_SCRIPT" "$@"
set +x

echo
printf 'Done. You can rerun with explicit options, e.g.:\n'
printf '  %q --yes --owl-repo <url> --mire-repo <url> --mire-lib-repo <url> --kioto-repo <url>\n' "$BASE_SCRIPT"
