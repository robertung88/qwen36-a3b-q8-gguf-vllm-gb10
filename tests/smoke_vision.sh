#!/usr/bin/env bash
set -euo pipefail
BASE_URL=${BASE_URL:-http://127.0.0.1:8000}
MODEL=${MODEL:-qwen36-35b-a3b-q8}
RED_PNG='iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC'
cat >/tmp/qwen36-vision-payload.json <<JSON
{"model":"$MODEL","messages":[{"role":"user","content":[{"type":"text","text":"What color is this image? Answer one word."},{"type":"image_url","image_url":{"url":"data:image/png;base64,$RED_PNG"}}]}],"max_tokens":16,"temperature":0}
JSON
resp=$(curl -fsS --max-time 180 "$BASE_URL/v1/chat/completions" -H 'Content-Type: application/json' --data @/tmp/qwen36-vision-payload.json)
RESP_JSON="$resp" python3 - <<'PY'
import json, os, re
d=json.loads(os.environ['RESP_JSON'])
content=d['choices'][0]['message'].get('content','')
assert re.search('red', content, re.I), d
print('OK vision:', content, d.get('usage'))
PY
