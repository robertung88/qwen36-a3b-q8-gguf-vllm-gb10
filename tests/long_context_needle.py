#!/usr/bin/env python3
import argparse, json, time, urllib.request

parser = argparse.ArgumentParser(description='Long-context needle retrieval smoke test for GB10 VLLM')
parser.add_argument('--base-url', default='http://127.0.0.1:8000')
parser.add_argument('--model', default='qwen36-35b-a3b-q8')
parser.add_argument('--target-tokens', type=int, default=65536)
parser.add_argument('--timeout', type=int, default=1200)
args = parser.parse_args()

code = f'NEEDLE-{args.target_tokens}-{int(time.time())}'
filler = max(1000, args.target_tokens - 140)
before = filler // 2
after = filler - before
content = (
    'Long-context retrieval test.\n'
    + (' apple' * before)
    + f'\nIMPORTANT_SECRET_CODE: {code}\n'
    + (' apple' * after)
    + '\nQuestion: What is the IMPORTANT_SECRET_CODE? Answer only the code.'
)
payload = {
    'model': args.model,
    'messages': [{'role': 'user', 'content': content}],
    'max_tokens': 24,
    'temperature': 0,
}
req = urllib.request.Request(
    args.base_url.rstrip('/') + '/v1/chat/completions',
    data=json.dumps(payload).encode(),
    headers={'Content-Type': 'application/json'},
    method='POST',
)
t0 = time.time()
with urllib.request.urlopen(req, timeout=args.timeout) as r:
    data = json.loads(r.read().decode())
elapsed = time.time() - t0
out = data['choices'][0]['message'].get('content', '')
usage = data.get('usage') or {}
assert code in out, data
assert usage.get('prompt_tokens', 0) > args.target_tokens * 0.92, usage
print(json.dumps({'ok': True, 'elapsed_sec': round(elapsed, 3), 'expected_code': code, 'content': out, 'usage': usage}, indent=2))
