#!/usr/bin/env bash
set -euo pipefail

input_file="${1:-input/step.dat}"
run_dir="${2:-runs/default}"

if [[ ! -f "$input_file" ]]; then
  echo "Input file not found: $input_file" >&2
  exit 2
fi

if [[ ! -x step ]]; then
  make
fi

mkdir -p "$run_dir"
cp "$input_file" "$run_dir/step.dat"
cp step "$run_dir/step"

(
  cd "$run_dir"
  ./step | tee run.log
)

python3 scripts/check_outputs.py \
  --log "$run_dir/run.log" \
  --div "$run_dir/step2-div.dat" \
  --psi "$run_dir/step2-psi.dat"