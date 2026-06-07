#!/usr/bin/env bash
set -euo pipefail
BASE_URL=${BASE_URL:-http://127.0.0.1:8000}
EXPECTED_MODEL=${EXPECTED_MODEL:-${MODEL:-qwen36-35b-a3b-q8}}
EXPECTED_ROOT_FRAGMENT=${EXPECTED_ROOT_FRAGMENT:-Qwen3.6-35B-A3B-UD-Q8_K_XL.gguf}

models=$(curl -fsS --max-time 10 "$BASE_URL/v1/models")
MODELS_JSON="$models" EXPECTED_MODEL="$EXPECTED_MODEL" EXPECTED_ROOT_FRAGMENT="$EXPECTED_ROOT_FRAGMENT" python3 - <<'PY'
import json, os
expected_model=os.environ['EXPECTED_MODEL']
expected_root=os.environ['EXPECTED_ROOT_FRAGMENT']
d=json.loads(os.environ['MODELS_JSON'])
m=d['data'][0]
assert m['id']==expected_model, m
assert m['max_model_len']==262144, m
assert expected_root in m['root'], m
print('OK models:', m['id'], m['root'], m['max_model_len'])
PY
curl -fsS --max-time 5 "$BASE_URL/health" >/dev/null
