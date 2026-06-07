#!/usr/bin/env bash
set -euo pipefail
BASE_URL=${BASE_URL:-http://127.0.0.1:8000}
MODEL=${MODEL:-qwen36-35b-a3b-q8}
cat >/tmp/qwen36-tool-payload.json <<JSON
{"model":"$MODEL","messages":[{"role":"user","content":"Call the get_weather tool with city Paris."}],"tools":[{"type":"function","function":{"name":"get_weather","description":"Get current weather for a city.","parameters":{"type":"object","properties":{"city":{"type":"string"}},"required":["city"]}}}],"tool_choice":"auto","max_tokens":64,"temperature":0}
JSON
resp=$(curl -fsS --max-time 180 "$BASE_URL/v1/chat/completions" -H 'Content-Type: application/json' --data @/tmp/qwen36-tool-payload.json)
RESP_JSON="$resp" python3 - <<'PY'
import json, os
d=json.loads(os.environ['RESP_JSON'])
msg=d['choices'][0]['message']
tools=msg.get('tool_calls') or []
assert tools and tools[0]['function']['name']=='get_weather' and 'Paris' in tools[0]['function']['arguments'], d
print('OK tools:', tools, d.get('usage'))
PY
