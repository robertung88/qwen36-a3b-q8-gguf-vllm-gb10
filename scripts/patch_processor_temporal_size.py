#!/usr/bin/env python3
"""Set Qwen3.6/Qwen3.5 VL processor temporal_patch_size to 1.

For the tested Unsloth Qwen3.6 35B-A3B GGUF + mmproj-BF16 path, VLLM's
Qwen3 VL Conv3D patch embed expects temporal_patch_size=1. Some downloaded
processor_config.json files may contain 2, which can make image requests crash
with a Conv3D reshape error.
"""
import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("model_dir", type=Path, help="Directory containing processor_config.json")
args = parser.parse_args()
path = args.model_dir / "processor_config.json"
config = json.loads(path.read_text())
changed = False
for key, value in list(config.items()):
    if isinstance(value, dict) and "temporal_patch_size" in value and value["temporal_patch_size"] != 1:
        value["temporal_patch_size"] = 1
        changed = True
    if key == "temporal_patch_size" and config[key] != 1:
        config[key] = 1
        changed = True
if changed:
    path.write_text(json.dumps(config, indent=2) + "\n")
print(f"{path}: temporal_patch_size=1 ({'changed' if changed else 'already ok'})")
