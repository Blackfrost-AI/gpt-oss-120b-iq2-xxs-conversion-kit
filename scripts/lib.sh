#!/usr/bin/env bash
# shellcheck disable=SC2034

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$KIT_ROOT/.env}"

if [[ ! -r "$CONFIG_FILE" ]]; then
    printf 'Missing configuration: %s\nCopy .env.example to .env and edit it.\n' "$CONFIG_FILE" >&2
    exit 2
fi

set -a
# shellcheck disable=SC1090
source "$CONFIG_FILE"
set +a

: "${WORK_ROOT:?Set WORK_ROOT in .env}"
: "${SOURCE_GGUF:?Set SOURCE_GGUF in .env}"
: "${IMATRIX:?Set IMATRIX in .env}"
: "${OUTPUT_GGUF:?Set OUTPUT_GGUF in .env}"

THREADS="${THREADS:-$(nproc)}"
MIN_FREE_BYTES="${MIN_FREE_BYTES:-75000000000}"
RUN_LOAD_CHECK="${RUN_LOAD_CHECK:-false}"
BASE_MODEL="${BASE_MODEL:-openai/gpt-oss-120b}"
BASE_REVISION="${BASE_REVISION:-b5c939de8f754692c1647ca79fbf85e8c1e70f8a}"
SOURCE_LLAMA_COMMIT="${SOURCE_LLAMA_COMMIT:-9a3bf2b84923a85583b4ee8177b0cca13824bb03}"
QUANT_LLAMA_COMMIT="${QUANT_LLAMA_COMMIT:-7e4c0a96880dae4fc4268ad441f8a6446bd5460a}"
IMATRIX_REPO="${IMATRIX_REPO:-bartowski/openai_gpt-oss-120b-GGUF}"
IMATRIX_REVISION="${IMATRIX_REVISION:-8d64014efc314685c68ad448590f905fcb20e534}"
IMATRIX_FILENAME="${IMATRIX_FILENAME:-openai_gpt-oss-120b-imatrix.gguf}"

TOOLS_DIR="$WORK_ROOT/tools"
SOURCE_LLAMA_DIR="$TOOLS_DIR/llama-source"
QUANT_LLAMA_DIR="$TOOLS_DIR/llama-quant"
SOURCE_VENV="$TOOLS_DIR/source-venv"
HF_SOURCE_DIR="$WORK_ROOT/hf-source"
SOURCE_BF16_GGUF="$WORK_ROOT/source/gpt-oss-120b-BF16.gguf"
LOG_DIR="$WORK_ROOT/logs"
QUANTIZE_BIN="$QUANT_LLAMA_DIR/build/bin/llama-quantize"
LLAMA_CLI_BIN="$QUANT_LLAMA_DIR/build/bin/llama-cli"

[[ "$WORK_ROOT" != "/" ]] || { echo 'WORK_ROOT must not be /' >&2; exit 2; }
[[ "$SOURCE_GGUF" != "/" ]] || { echo 'SOURCE_GGUF must not be /' >&2; exit 2; }
[[ "$IMATRIX" != "/" ]] || { echo 'IMATRIX must not be /' >&2; exit 2; }
[[ "$OUTPUT_GGUF" != "/" ]] || { echo 'OUTPUT_GGUF must not be /' >&2; exit 2; }
[[ "$THREADS" =~ ^[1-9][0-9]*$ ]] || { echo 'THREADS must be a positive integer' >&2; exit 2; }
[[ "$MIN_FREE_BYTES" =~ ^[1-9][0-9]*$ ]] || { echo 'MIN_FREE_BYTES must be a positive integer' >&2; exit 2; }
[[ "$RUN_LOAD_CHECK" == "true" || "$RUN_LOAD_CHECK" == "false" ]] || {
    echo 'RUN_LOAD_CHECK must be true or false' >&2
    exit 2
}

require_commands() {
    local missing=0 command_name
    for command_name in "$@"; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            printf 'Missing required command: %s\n' "$command_name" >&2
            missing=1
        fi
    done
    (( missing == 0 ))
}

assert_artifact() {
    local path="$1" expected_size="$2" expected_sha="$3" label="$4"
    local actual_size actual_sha
    [[ -f "$path" ]] || { printf '%s is missing: %s\n' "$label" "$path" >&2; return 1; }
    actual_size="$(stat -c '%s' "$path")"
    [[ "$actual_size" == "$expected_size" ]] || {
        printf '%s size mismatch\nexpected: %s\nactual:   %s\n' "$label" "$expected_size" "$actual_size" >&2
        return 1
    }
    actual_sha="$(sha256sum "$path" | awk '{print $1}')"
    [[ "$actual_sha" == "$expected_sha" ]] || {
        printf '%s SHA-256 mismatch\nexpected: %s\nactual:   %s\n' "$label" "$expected_sha" "$actual_sha" >&2
        return 1
    }
}

assert_source_and_imatrix() {
    assert_artifact "$SOURCE_GGUF" "$EXPECTED_SOURCE_SIZE" "$EXPECTED_SOURCE_SHA256" 'source GGUF'
    assert_artifact "$IMATRIX" "$EXPECTED_IMATRIX_SIZE" "$EXPECTED_IMATRIX_SHA256" 'importance matrix'
}

assert_quant_toolchain() {
    [[ -x "$QUANTIZE_BIN" ]] || { printf 'Missing executable: %s\n' "$QUANTIZE_BIN" >&2; return 1; }
    [[ "$(git -C "$QUANT_LLAMA_DIR" rev-parse HEAD)" == "$QUANT_LLAMA_COMMIT" ]] || {
        echo 'Quantization llama.cpp commit does not match the pin.' >&2
        return 1
    }
}

assert_free_space() {
    local target_dir="$1" available
    mkdir -p "$target_dir"
    available="$(df -PB1 "$target_dir" | awk 'NR == 2 {print $4}')"
    if (( available < MIN_FREE_BYTES )); then
        printf 'Need at least %s free bytes in %s; found %s.\n' "$MIN_FREE_BYTES" "$target_dir" "$available" >&2
        return 1
    fi
}
