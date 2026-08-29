#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_commands hf sha256sum
mkdir -p "$HF_SOURCE_DIR" "$(dirname -- "$IMATRIX")"

hf download "$BASE_MODEL" \
    --revision "$BASE_REVISION" \
    --local-dir "$HF_SOURCE_DIR"

hf download "$IMATRIX_REPO" "$IMATRIX_FILENAME" \
    --revision "$IMATRIX_REVISION" \
    --local-dir "$(dirname -- "$IMATRIX")"

assert_artifact "$IMATRIX" "$EXPECTED_IMATRIX_SIZE" "$EXPECTED_IMATRIX_SHA256" 'importance matrix'
echo 'Pinned Hugging Face assets are ready.'
