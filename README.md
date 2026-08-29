# GPT-OSS-120B IQ2_XXS conversion kit

Reproducible, conversion-only tooling for the clean GPT-OSS-120B
MXFP4-to-IQ2_XXS GGUF build. This repository contains no model weights and no
behavioral weight modifications.

The verified output is `gpt-oss-120b-IQ2_XXS.gguf`, 66,080,446,048 bytes, with
SHA-256:

```text
87e59d610a38f75834d18e1f9c87b0eeb45b7feeff488c3426e62be2faa9a8d6
```

## What the name means

`IQ2_XXS` is the model-level quantization target, not a promise that every
tensor has that type. GPT-OSS-120B has 2880-wide expert matrices that cannot use
the IQ2_XXS block layout. The pinned `llama-quantize` build therefore selected a
valid mixed layout automatically. The successful run reported 217 fallback
tensors and a final effective size of 4.52 BPW. Do not add `--pure`.

## Quick start

Requirements: Linux, Git, CMake, a C/C++ compiler, Python 3, enough disk space,
and the Hugging Face `hf` CLI for asset preparation.

```bash
cp .env.example .env
# Edit WORK_ROOT and, if needed, THREADS.

make setup
make assets
make source       # skip when SOURCE_GGUF already matches the recorded hash
make preflight
make convert
make validate
```

The exact quantization command executed by `make convert` is:

```bash
llama-quantize \
  --imatrix openai_gpt-oss-120b-imatrix.gguf \
  gpt-oss-120b-MXFP4.gguf \
  gpt-oss-120b-IQ2_XXS.gguf \
  IQ2_XXS \
  192
```

Read [the recipe](docs/RECIPE.md), [validation notes](docs/VALIDATION.md), and
[mixed-tensor explanation](docs/MIXED-TENSORS.md) before rerunning it.

## Scope

This kit is deliberately limited to the clean conversion. It does not contain
fine-tuning, experimental weights, prompts, benchmark conversations, or server
state.
