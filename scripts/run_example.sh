#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: scripts/run_example.sh EXAMPLE_DIR RUN_DIR" >&2
  exit 2
fi

example_dir="$1"
run_dir="$2"

if [ ! -f "step" ]; then
  make
fi

mkdir -p "$run_dir"
cp "$example_dir/step.dat" "$run_dir/step.dat"
cp step "$run_dir/step"

(
  cd "$run_dir"
  ./step | tee run.log
)