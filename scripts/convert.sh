#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_commands git sha256sum tee
assert_source_and_imatrix
assert_quant_toolchain
assert_free_space "$(dirname -- "$OUTPUT_GGUF")"
[[ ! -e "$OUTPUT_GGUF" ]] || { printf 'Refusing to overwrite: %s\n' "$OUTPUT_GGUF" >&2; exit 2; }
mkdir -p "$(dirname -- "$OUTPUT_GGUF")" "$LOG_DIR"

"$QUANTIZE_BIN" \
    --imatrix "$IMATRIX" \
    "$SOURCE_GGUF" \
    "$OUTPUT_GGUF" \
    IQ2_XXS \
    "$THREADS" \
    |& tee "$LOG_DIR/iq2-xxs-quantize.log"

assert_artifact "$OUTPUT_GGUF" "$EXPECTED_OUTPUT_SIZE" "$EXPECTED_OUTPUT_SHA256" 'IQ2_XXS output'
sha256sum "$OUTPUT_GGUF" | tee "$LOG_DIR/iq2-xxs-output.sha256"
echo 'Conversion completed and the output matches the reference artifact.'
