# Validation record

The successful clean conversion produced:

| Property | Value |
|---|---:|
| File | `gpt-oss-120b-IQ2_XXS.gguf` |
| Size | 66,080,446,048 bytes |
| SHA-256 | `87e59d610a38f75834d18e1f9c87b0eeb45b7feeff488c3426e62be2faa9a8d6` |
| Model-level type | IQ2_XXS |
| Effective size | 4.52 BPW |
| Tensor count | 687 |
| Fallback tensors | 217 |

The artifact also passed a CPU-only `llama-cli` load check with a 512-token
context and zero generated tokens. The model loaded in 36.69 seconds on the
reference host.

`scripts/validate.sh` always checks exact size and SHA-256. Set
`RUN_LOAD_CHECK=true` in `.env` to repeat the optional load check.
