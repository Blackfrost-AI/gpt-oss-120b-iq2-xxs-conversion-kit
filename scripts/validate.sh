#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_commands sha256sum
assert_artifact "$OUTPUT_GGUF" "$EXPECTED_OUTPUT_SIZE" "$EXPECTED_OUTPUT_SHA256" 'IQ2_XXS output'

if [[ "$RUN_LOAD_CHECK" == "true" ]]; then
    [[ -x "$LLAMA_CLI_BIN" ]] || { printf 'Missing executable: %s\n' "$LLAMA_CLI_BIN" >&2; exit 2; }
    mkdir -p "$LOG_DIR"
    "$LLAMA_CLI_BIN" \
        -m "$OUTPUT_GGUF" \
        -c 512 \
        -n 0 \
        -t "$THREADS" \
        |& tee "$LOG_DIR/iq2-xxs-load-check.log"
fi

echo 'Output size and SHA-256 are valid.'
