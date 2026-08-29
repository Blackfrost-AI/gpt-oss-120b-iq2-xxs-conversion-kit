#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_commands git sha256sum tee
assert_source_and_imatrix
assert_quant_toolchain
assert_free_space "$(dirname -- "$OUTPUT_GGUF")"
mkdir -p "$LOG_DIR"

DRY_RUN_LOG="$LOG_DIR/iq2-xxs-dry-run.log"
"$QUANTIZE_BIN" \
    --dry-run \
    --imatrix "$IMATRIX" \
    "$SOURCE_GGUF" \
    IQ2_XXS \
    "$THREADS" \
    |& tee "$DRY_RUN_LOG"

grep -Fq 'quant size  = 63006.80 MiB (4.52 BPW)' "$DRY_RUN_LOG"
grep -Fq 'WARNING: 217 of 687 tensor(s) required fallback quantization' "$DRY_RUN_LOG"
echo 'Preflight passed: inputs, toolchain, disk space, and tensor plan match the reference run.'
