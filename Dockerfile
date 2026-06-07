FROM ghcr.io/spark-arena/dgx-vllm-eugr-nightly-tf5:latest
COPY files/vllm/model_executor/model_loader/gguf_loader.py /usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/gguf_loader.py
COPY files/vllm/model_executor/model_loader/weight_utils.py /usr/local/lib/python3.12/dist-packages/vllm/model_executor/model_loader/weight_utils.py
COPY files/vllm/model_executor/layers/quantization/gguf.py /usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/quantization/gguf.py
COPY files/vllm/model_executor/layers/linear.py /usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/linear.py
COPY files/vllm/model_executor/layers/mamba/mamba_mixer2.py /usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/mamba/mamba_mixer2.py
COPY files/vllm/transformers_utils/config.py /usr/local/lib/python3.12/dist-packages/vllm/transformers_utils/config.py
COPY files/vllm/config/speculative.py /usr/local/lib/python3.12/dist-packages/vllm/config/speculative.py
COPY files/vllm/model_executor/models/registry.py /usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/registry.py
COPY files/vllm/model_executor/models/qwen3_5.py /usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5.py
COPY files/vllm/model_executor/models/qwen3_5_mtp.py /usr/local/lib/python3.12/dist-packages/vllm/model_executor/models/qwen3_5_mtp.py
LABEL org.opencontainers.image.title="qwen36-a3b-q8-gguf-vllm-gb10"
