#!/usr/bin/env bash
set -euo pipefail
BASE_URL=${BASE_URL:-http://127.0.0.1:8000}
MODEL=${MODEL:-qwen36-35b-a3b-q8}
resp=$(curl -fsS --max-time 120 "$BASE_URL/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Answer in one word: what is the capital of France?\"}],\"max_tokens\":16,\"temperature\":0}")
RESP_JSON="$resp" python3 - <<'PY'
import json, os
d=json.loads(os.environ['RESP_JSON'])
content=d['choices'][0]['message'].get('content','')
assert 'Paris' in content, d
print('OK text:', content, d.get('usage'))
PY
