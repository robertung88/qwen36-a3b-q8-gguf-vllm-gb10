# Upstreaming Plan

This repo is a field-tested integration snapshot. For upstream VLLM, split the work into small PRs.

Recommended PR sequence:

1. Qwen3.5/Qwen3.6 MoE GGUF architecture mapping:
   - `qwen35moe`
   - `qwen3_5_moe_text`
   - multimodal wrapper handling
2. GGUF sharding and merged-column ordering fixes, if not already merged.
3. Qwen3.5/Qwen3.6 Gated DeltaNet GGUF conversions:
   - value-head even/odd reorder
   - `ssm_a = -exp(A_log)` -> `A_log`
4. Qwen3.5 RMSNorm GGUF scale-to-offset adjustment.
5. Qwen3.5 VL mmproj mappings:
   - `v.post_ln.*`
   - `mm.0.*`
   - `mm.2.*`
6. GGUF MTP draft loading:
   - preserve `hf_config_path`
   - map `blk.<base_layers>.nextn.*`
   - initialize draft with draft `model_config`
7. Minimal tests/fixtures for each mapping where possible.

Avoid trying to upstream this entire snapshot as one PR.
