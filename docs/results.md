# Validation Results

Representative results from a GB10/GX10 validation run.

## Server config

```text
model: unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q8_K_XL
projector: mmproj-BF16.gguf
max_model_len: 262144
gpu_memory_utilization: 0.82
max_num_batched_tokens: 2048
max_num_seqs: 6
speculative_config: {"method":"mtp","num_speculative_tokens":2}
```

## Feature checks

| Check | Result |
|---|---|
| `/v1/models` | root contained `Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf`, `max_model_len=262144` |
| Text | `Paris` one-word smoke test |
| Tools | Parsed `get_weather({"city":"Paris"})` |
| Vision | 1x1 red PNG -> `Red` |
| Concurrency | 6 concurrent arithmetic requests all correct |
| Long context | needles retrieved at ~65k, ~131k, and ~260k prompt tokens |
| MTP | non-zero drafted/accepted metrics; short smoke accepted all drafted tokens |

## Observed memory/KV logs

```text
Model loading took 37.37 GiB memory
Available KV cache memory: ~60 GiB
GPU KV cache size: ~2.7M tokens
Maximum concurrency for 262,144 tokens per request: ~10.4x
```

## MTP metrics shape

```text
vllm:spec_decode_num_drafts_total{...} > 0
vllm:spec_decode_num_draft_tokens_total{...} > 0
vllm:spec_decode_num_accepted_tokens_total{...} > 0
```
