# Exact recipe

## Inputs

- Base model: `openai/gpt-oss-120b`
- Base revision: `b5c939de8f754692c1647ca79fbf85e8c1e70f8a`
- MXFP4 source size: 63,387,346,208 bytes
- MXFP4 source SHA-256: `582bd40f6886200101f4c4ed9f25f3fe80cc14c86e9e2b37746cd8904a0c622d`
- Importance matrix size: 161,600,480 bytes
- Importance matrix SHA-256: `a2ee62f0d685d497b6e39e60a0827b639b63ea42930d3ad5573d8bccb29f3729`
- Importance matrix revision: `8d64014efc314685c68ad448590f905fcb20e534`

The source model was converted with llama.cpp commit
`9a3bf2b84923a85583b4ee8177b0cca13824bb03`. The IQ2_XXS conversion used
commit `7e4c0a96880dae4fc4268ad441f8a6446bd5460a`, build 10434.

## Stages

1. Download the pinned Hugging Face model and importance matrix with
   `scripts/download_assets.sh`.
2. Convert the Hugging Face model to BF16 GGUF, then MXFP4_MOE, using
   `scripts/prepare_source.sh`. This intermediate stage is skippable when the
   source GGUF already matches the recorded size and hash.
3. Run `scripts/preflight.sh`. Its dry-run must report 63,006.80 MiB at 4.52
   BPW and 217 fallback tensors out of 687.
4. Run `scripts/convert.sh`. It refuses to overwrite an existing output.
5. Run `scripts/validate.sh` and compare both byte count and SHA-256.

The reference machine used 192 CPU threads. Quantization took 418,335.40 ms,
about 6 minutes 58 seconds. Runtime varies with storage and CPU throughput.

## Storage

The end-to-end path may temporarily hold the Hugging Face shards, a BF16 GGUF,
the MXFP4 source, the importance matrix, and the IQ2_XXS output. Plan for at
least 260 GB when recreating every stage. If the source already exists, the
conversion script requires at least 75 GB free by default.
