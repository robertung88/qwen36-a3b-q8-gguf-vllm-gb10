# Troubleshooting Notes

## Stock VLLM cannot parse `qwen35moe` GGUF

Symptom:

```text
GGUF model with architecture qwen35moe is not supported yet
```

This happens especially in speculative/draft config paths that try to inspect the GGUF with Transformers. The patched recipe passes the HF config path into the draft `ModelConfig` and adds Qwen3.5/Qwen3.6 GGUF mappings.

## Model loads but produces garbage

The main correctness issues found were Gated DeltaNet and RMSNorm layout mismatches:

- llama.cpp GGUF value-head order differed from HF/VLLM order.
- GGUF stores `ssm_a = -exp(A_log)` while VLLM expects `A_log`.
- Qwen3.5 RMSNorm GGUF stores full scale while VLLM's Gemma-style RMSNorm expects an offset.

The patched `weight_utils.py` handles these conversions.

## Vision request crashes in Conv3D reshape

For the tested mmproj path, `processor_config.json` needed `temporal_patch_size=1`.

Run:

```bash
python3 scripts/patch_processor_temporal_size.py /path/to/model-dir
```

## MTP initializes the wrong model architecture

The draft loader may call `initialize_model()` with the target VLLM config rather than the draft model config. The patched GGUF loader shallow-replaces `vllm_config.model_config` for initialization when an explicit draft model config is passed.

## High prefill setting fails

The tested stable full-context setting was:

```text
--max-num-batched-tokens 2048
```

Larger settings can trigger different FusedMoE/runner paths. Increase only after re-running smoke and long-context tests.
