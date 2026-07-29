#!/usr/bin/env bash
set -euo pipefail

make
while IFS= read -r example; do
  run_dir="runs/${example}"
  scripts/run_example.sh "examples/${example}" "$run_dir"
  python3 scripts/validate_run.py \
    --run-dir "$run_dir" \
    --expected "examples/${example}/expected.json" \
    --reference "examples/${example}/reference"
done < <(python3 - <<'PY'
import json
from pathlib import Path

for expected_path in sorted(Path("examples").glob("*/expected.json")):
    if json.loads(expected_path.read_text())["valid"]:
        print(expected_path.parent.name)
PY
)