# Qwen3.6 35B-A3B Q8 GGUF on VLLM for NVIDIA GB10/GX10

Experimental recipe for serving [`unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q8_K_XL`](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-MTP-GGUF) with VLLM on an NVIDIA GB10 / ASUS Ascent GX10 class machine.

This is **not stock VLLM support**. It is a working patched snapshot for the Qwen3.5/Qwen3.6 hybrid MoE GGUF path, including:

- Q8 GGUF loading
- 262,144-token context
- OpenAI-compatible chat completions
- OpenAI tool calls via `qwen3_coder`
- OpenAI image input via `mmproj-BF16.gguf`
- MTP speculative decoding (`num_speculative_tokens=2`)
- multi-request serving (`--max-num-seqs 6` in the tested profile)

## Tested environment

| Item | Value |
|---|---|
| Hardware | NVIDIA GB10 / ASUS Ascent GX10 class system |
| OS | Ubuntu 24.04 class, aarch64 |
| Base image | `ghcr.io/spark-arena/dgx-vllm-eugr-nightly-tf5:latest` |
| VLLM | `0.22.1rc1.dev3+g5dbf1605a.d20260529` in the base image |
| Model | `unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q8_K_XL` |
| Vision projector | `mmproj-BF16.gguf` |
| Context tested | 262,144 tokens |

## What worked in validation

- `/v1/models` reported the Q8 GGUF root and `max_model_len=262144`.
- Text smoke: capital of France -> `Paris`.
- Tool call smoke: parsed `get_weather({"city": "Paris"})`.
- Vision smoke: 1x1 red PNG -> `Red`.
- Six concurrent small chat requests completed successfully.
- Long-context needles retrieved at ~65k, ~131k, and ~260k prompt tokens.
- MTP metrics exposed non-zero drafted/accepted counters; short smoke tests had 100% acceptance.

Observed on the tested GB10 profile:

```text
Model loading took: ~37.37 GiB
GPU KV cache size: ~2.73M tokens
Maximum concurrency for 262,144-token requests: ~10.4x
```

## Quick start

### 1. Prepare model files

Download the GGUF and model-side config/tokenizer files from Hugging Face. The run scripts assume this host layout:

```text
$HOME/models/qwen36-35b-a3b-mtp-gguf-ud-q8-k-xl/
  Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf
  mmproj-BF16.gguf
  config.json
  tokenizer.json / tokenizer_config.json / chat_template files
  processor_config.json
```

Patch the processor temporal size if needed:

```bash
python3 scripts/patch_processor_temporal_size.py \
  $HOME/models/qwen36-35b-a3b-mtp-gguf-ud-q8-k-xl
```

For the tested model/projector path, `temporal_patch_size=1` was required for image requests.

### 2. Build the patched image

```bash
docker build -t qwen36-a3b-q8-gguf-vllm-gb10:latest .
```

### 3. Run VLLM

```bash
./scripts/run-vllm-q8.sh
```

By default this serves:

```text
http://localhost:8000/v1
model: qwen36-35b-a3b-q8
```

Override paths/names if needed:

```bash
MODELS_HOST_DIR=/data/models \
SERVED_MODEL_NAME=my-qwen36-q8 \
PORT=8000 \
./scripts/run-vllm-q8.sh
```

## Verify

```bash
BASE_URL=http://localhost:8000 MODEL=qwen36-35b-a3b-q8 tests/verify_live.sh
BASE_URL=http://localhost:8000 MODEL=qwen36-35b-a3b-q8 tests/smoke_text.sh
BASE_URL=http://localhost:8000 MODEL=qwen36-35b-a3b-q8 tests/smoke_tools.sh
BASE_URL=http://localhost:8000 MODEL=qwen36-35b-a3b-q8 tests/smoke_vision.sh
BASE_URL=http://localhost:8000 MODEL=qwen36-35b-a3b-q8 python3 tests/long_context_needle.py --target-tokens 65536
```

Check MTP metrics:

```bash
curl -s http://localhost:8000/metrics | grep -E 'spec_decode_num_(draft|accepted).*total'
```

## Systemd example

A generic unit is provided in:

```text
systemd/qwen36-q8-vllm.service
```

Install/adapt it for your username and model path.

## What was patched

The patched VLLM snapshot includes fixes/workarounds for:

1. GGUF architecture mapping for Qwen3.5/Qwen3.6 MoE (`qwen35moe`, `qwen3_5_moe_text`).
2. GGUF tuple/multi-index shard loading and merged-column ordering.
3. Qwen3.5/Qwen3.6 Gated DeltaNet tensor layout conversion:
   - llama.cpp GGUF value-head order -> HF/VLLM order
   - `ssm_a = -exp(A_log)` -> `A_log`
4. Qwen3.5 RMSNorm GGUF scale-vs-offset adjustment.
5. Routed MoE expert tensors forced through GGUF qweight paths, including raw BF16/F16/F32 fallback tensors.
6. Qwen3.5 VL `mmproj-BF16.gguf` merger mappings.
7. MTP draft-model GGUF loading:
   - pass target `hf_config_path` to draft `ModelConfig`
   - map `blk.<base_layers>.nextn.*` tensors to VLLM MTP weights
   - initialize draft with draft `model_config`
8. Small shape guards for GGUF single-output tensors, Mamba/SSM tensors, and Conv3D patch embedding.

The base inspiration came from upstream VLLM work, especially PRs related to Qwen3.5 GGUF and GGUF sharding/slot ordering. The goal here is a reproducible field-tested recipe, not a claim that all patches are upstream-ready as-is.

## Caveats

- This is experimental and tied to the tested VLLM nightly/base image.
- It is not guaranteed to work on stock `vllm/vllm-openai` images.
- `--max-num-batched-tokens 2048` was the stable tested full-context setting. Much larger prefill settings can hit different runner paths.
- Vision was validated with a small OpenAI image input smoke test, not exhaustive VQA benchmarking.
- MTP was validated by VLLM logs and metrics counters, plus coherent text/tool/vision/long-context behavior.
- No model weights are included in this repo.

## License

Repository code is Apache-2.0. Modified VLLM files retain their SPDX Apache-2.0 headers and remain under the VLLM project's license terms.
