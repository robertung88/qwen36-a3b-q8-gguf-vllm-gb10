# Draft Hugging Face Discussion Post

Title:

```text
GB10/GX10: Qwen3.6-35B-A3B UD-Q8_K_XL GGUF working under patched VLLM with 262k context, MTP, tools, and vision
```

Post:

```markdown
Hi all — I wanted to share a field-tested recipe for running this GGUF variant under VLLM on an NVIDIA GB10 / ASUS Ascent GX10 class machine.

Repo with Dockerfile, patched VLLM files, run command, systemd example, and smoke tests:

https://github.com/robertung88/qwen36-a3b-q8-gguf-vllm-gb10

## What is working

Using `unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q8_K_XL` plus `mmproj-BF16.gguf`, I was able to serve the model with a patched VLLM image and validate:

- OpenAI-compatible `/v1/chat/completions`
- `max_model_len=262144`
- OpenAI tool calling via `--enable-auto-tool-choice --tool-call-parser qwen3_coder`
- OpenAI image input via `mmproj-BF16.gguf`
- MTP speculative decoding with `num_speculative_tokens=2`
- 6 concurrent small requests
- long-context needle retrieval up to ~260k prompt tokens

This is **not stock VLLM support**; it required a patched VLLM snapshot.

## Tested environment

- Hardware: NVIDIA GB10 / ASUS Ascent GX10 class system
- Base image: `ghcr.io/spark-arena/dgx-vllm-eugr-nightly-tf5:latest`
- VLLM in base image: `0.22.1rc1.dev3+g5dbf1605a.d20260529`
- Model: `Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf`
- Projector: `mmproj-BF16.gguf`

## Observed results

Representative logs from the working profile:

```text
Model loading took ~37.37 GiB
GPU KV cache size ~2.7M tokens
Maximum concurrency for 262,144-token requests ~10.4x
```

Smoke tests passed for:

- text: capital of France -> `Paris`
- tools: parsed `get_weather({"city":"Paris"})`
- vision: 1x1 red PNG -> `Red`
- long context: needle retrieval at ~65k, ~131k, and ~260k prompt tokens
- MTP: VLLM metrics exposed non-zero drafted/accepted token counters

## Main issues that needed patches

The biggest blockers were:

1. VLLM/Transformers GGUF paths did not understand `qwen35moe` / Qwen3.5 MoE GGUF architecture.
2. Qwen3.5/Qwen3.6 Gated DeltaNet tensors in llama.cpp GGUF use a different value-head ordering than HF/VLLM.
3. GGUF stores `ssm_a = -exp(A_log)`, while VLLM expects `A_log`.
4. Qwen3.5 RMSNorm GGUF tensors store full scale; VLLM's Gemma-style RMSNorm expects an offset.
5. Routed MoE expert tensors, including raw BF16 fallback tensors, needed to load through GGUF qweight paths.
6. MTP needed explicit mapping for `blk.<base_layers>.nextn.*` tensors and draft-model config handling.
7. For vision, the tested processor config needed `temporal_patch_size=1` with `mmproj-BF16.gguf`.

The repo documents these and includes the patched files used for the successful run.

## Caveats

- This is experimental and tied to the tested VLLM nightly image.
- It is a recipe/patch snapshot, not an official VLLM release.
- No model weights are redistributed in the repo.
- Vision was smoke-tested via OpenAI image input; it is not a full VQA benchmark.
- `--max-num-batched-tokens 2048` was the stable full-context setting in my tests.

Hope this helps others trying to run the Q8 GGUF path on GB10/GX10-class machines. Happy to compare notes if anyone is trying to upstream the Qwen3.5/Qwen3.6 GGUF + MTP pieces into VLLM.
```
