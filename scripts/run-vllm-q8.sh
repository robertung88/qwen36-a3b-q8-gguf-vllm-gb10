#!/usr/bin/env bash
set -euo pipefail

# Generic OpenAI-compatible VLLM server for:
# unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q8_K_XL
#
# Expected /models layout inside the container:
#   /models/qwen36-35b-a3b-mtp-gguf-ud-q8-k-xl/
#     Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf
#     mmproj-BF16.gguf
#     config.json / tokenizer files / processor_config.json
#
# You can set MODEL_DIR, GGUF_FILE, IMAGE, SERVED_MODEL_NAME, PORT, etc.

CONTAINER_NAME=${CONTAINER_NAME:-vllm-qwen36-q8}
IMAGE=${IMAGE:-qwen36-a3b-q8-gguf-vllm-gb10:latest}
MODELS_HOST_DIR=${MODELS_HOST_DIR:-$HOME/models}
MODEL_DIR=${MODEL_DIR:-qwen36-35b-a3b-mtp-gguf-ud-q8-k-xl}
GGUF_FILE=${GGUF_FILE:-Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf}
SERVED_MODEL_NAME=${SERVED_MODEL_NAME:-qwen36-35b-a3b-q8}
PORT=${PORT:-8000}
GPU_MEMORY_UTILIZATION=${GPU_MEMORY_UTILIZATION:-0.82}
MAX_NUM_SEQS=${MAX_NUM_SEQS:-6}
MAX_NUM_BATCHED_TOKENS=${MAX_NUM_BATCHED_TOKENS:-2048}
MAX_MODEL_LEN=${MAX_MODEL_LEN:-262144}
MTP_TOKENS=${MTP_TOKENS:-2}

docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  --gpus all \
  -v "$MODELS_HOST_DIR:/models" \
  -p "$PORT:8000" \
  --shm-size=16g \
  "$IMAGE" \
  vllm serve "/models/$MODEL_DIR/$GGUF_FILE" \
  --served-model-name "$SERVED_MODEL_NAME" \
  --host 0.0.0.0 --port 8000 --tensor-parallel-size 1 \
  --dtype float16 --load-format gguf --quantization gguf \
  --hf-config-path "/models/$MODEL_DIR" \
  --tokenizer "/models/$MODEL_DIR" \
  --max-model-len "$MAX_MODEL_LEN" --attention-backend flash_attn \
  --reasoning-parser qwen3 \
  --default-chat-template-kwargs '{"enable_thinking":false}' \
  --enable-auto-tool-choice --tool-call-parser qwen3_coder \
  --limit-mm-per-prompt '{"image":1,"video":0}' \
  --skip-mm-profiling --mm-encoder-tp-mode data \
  --generation-config vllm --gpu-memory-utilization "$GPU_MEMORY_UTILIZATION" \
  --max-num-batched-tokens "$MAX_NUM_BATCHED_TOKENS" --max-num-seqs "$MAX_NUM_SEQS" \
  --enable-prefix-caching --enable-chunked-prefill \
  --enforce-eager --trust-remote-code \
  --speculative-config "{\"method\":\"mtp\",\"num_speculative_tokens\":$MTP_TOKENS}"
