# Why the output is larger than the source

The source GGUF is 63.39 GB and the resulting IQ2_XXS GGUF is 66.08 GB. That is
expected for this model.

GPT-OSS-120B is a sparse mixture-of-experts model with 128 routed experts and
four active experts per token. Its routed expert matrices have a width of 2880,
which is incompatible with IQ2_XXS block requirements. The pinned
`llama-quantize` build selected compatible tensor types rather than emitting an
invalid file.

The conversion log recorded:

- 36 tensors converted to IQ2_XXS
- 176 tensors converted to IQ4_NL
- 36 tensors converted to Q5_0
- 5 tensors converted to Q4_0
- 217 of 687 tensors requiring fallback quantization
- 63,006.80 MiB final tensor size, or 4.52 BPW

The remaining tensors were retained in compatible source types. The model-level
label remains IQ2_XXS, but it is intentionally a mixed-tensor GGUF. Do not use
`--pure`, and do not describe the file as every tensor being 2-bit.
