#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_commands git sha256sum tee
[[ -f "$HF_SOURCE_DIR/config.json" ]] || { echo 'Run scripts/download_assets.sh first.' >&2; exit 2; }
[[ -x "$SOURCE_VENV/bin/python" ]] || { echo 'Run scripts/setup_toolchain.sh first.' >&2; exit 2; }
[[ "$(git -C "$SOURCE_LLAMA_DIR" rev-parse HEAD)" == "$SOURCE_LLAMA_COMMIT" ]] || {
    echo 'Source-conversion llama.cpp commit does not match the pin.' >&2
    exit 2
}
[[ ! -e "$SOURCE_BF16_GGUF" ]] || { printf 'Refusing to overwrite: %s\n' "$SOURCE_BF16_GGUF" >&2; exit 2; }
[[ ! -e "$SOURCE_GGUF" ]] || { printf 'Refusing to overwrite: %s\n' "$SOURCE_GGUF" >&2; exit 2; }

mkdir -p "$(dirname -- "$SOURCE_GGUF")" "$LOG_DIR"

"$SOURCE_VENV/bin/python" "$SOURCE_LLAMA_DIR/convert_hf_to_gguf.py" \
    "$HF_SOURCE_DIR" \
    --outtype bf16 \
    --outfile "$SOURCE_BF16_GGUF" \
    --model-name gpt-oss-120b \
    |& tee "$LOG_DIR/source-hf-to-gguf.log"

"$SOURCE_LLAMA_DIR/build/bin/llama-quantize" \
    "$SOURCE_BF16_GGUF" \
    "$SOURCE_GGUF" \
    MXFP4_MOE \
    "$THREADS" \
    |& tee "$LOG_DIR/source-mxfp4.log"

assert_artifact "$SOURCE_GGUF" "$EXPECTED_SOURCE_SIZE" "$EXPECTED_SOURCE_SHA256" 'source GGUF'
echo 'MXFP4 source created and verified. The intermediate BF16 file was retained.'
