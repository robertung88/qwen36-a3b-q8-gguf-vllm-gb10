#!/usr/bin/env bash
set -euo pipefail
DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
"$DIR/verify_live.sh"
"$DIR/smoke_text.sh"
"$DIR/smoke_tools.sh"
"$DIR/smoke_vision.sh"
python3 "$DIR/long_context_needle.py" --target-tokens "${LONG_CONTEXT_TARGET:-65536}"
