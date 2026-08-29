#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_commands git cmake python3
mkdir -p "$TOOLS_DIR"

checkout_llama() {
    local destination="$1" commit="$2"
    if [[ ! -d "$destination/.git" ]]; then
        git clone --filter=blob:none --no-checkout https://github.com/ggml-org/llama.cpp.git "$destination"
    fi
    git -C "$destination" fetch --depth 1 origin "$commit"
    git -C "$destination" checkout --detach "$commit"
}

build_llama() {
    local source_dir="$1"
    cmake -S "$source_dir" -B "$source_dir/build" \
        -DCMAKE_BUILD_TYPE=Release \
        -DGGML_NATIVE=ON \
        -DGGML_CUDA=OFF \
        -DLLAMA_CURL=OFF
    cmake --build "$source_dir/build" --target llama-quantize llama-cli -j "$(nproc)"
}

checkout_llama "$SOURCE_LLAMA_DIR" "$SOURCE_LLAMA_COMMIT"
checkout_llama "$QUANT_LLAMA_DIR" "$QUANT_LLAMA_COMMIT"
build_llama "$SOURCE_LLAMA_DIR"
build_llama "$QUANT_LLAMA_DIR"

if [[ ! -x "$SOURCE_VENV/bin/python" ]]; then
    python3 -m venv "$SOURCE_VENV"
fi
"$SOURCE_VENV/bin/python" -m pip install --upgrade pip
"$SOURCE_VENV/bin/python" -m pip install \
    -r "$SOURCE_LLAMA_DIR/requirements/requirements-convert_hf_to_gguf.txt"

echo 'Pinned llama.cpp toolchains are ready.'
