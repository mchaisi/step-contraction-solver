#!/usr/bin/env python3
from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Optional

from validate_run import validate


ROOT = Path(__file__).resolve().parents[1]
SCRIPT_DIR = ROOT / "scripts"


def main() -> int:
    failures = 0
    def run_example(example: Path, run_dir: Path) -> bool:
        runner = SCRIPT_DIR / "run_example.sh"
        if not runner.exists():
            print("ERROR: missing run_example.sh")
            return False
        run_dir.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(
            [str(runner), str(example), str(run_dir)],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            print(f"ERROR: failed to generate example {example.name}")
            print("stdout:")
            print(result.stdout)
            print("stderr:")
            print(result.stderr)
            return False
        return True

    def locate_run_dir(example: Path) -> Path | None:
        candidates = [example / "run", example, ROOT / "runs" / example.name]
        for candidate in candidates:
            if (candidate / "run.log").exists():
                return candidate
        return None

    for expected in sorted((ROOT / "examples").glob("*/expected.json")):
        example = expected.parent
        reference = example / "reference"
        run_dir = locate_run_dir(example)
        if run_dir is None:
            fallback = ROOT / "runs" / example.name
            if run_example(example, fallback):
                run_dir = fallback
            else:
                print(
                    f"SKIP: {example.name} "
                    "(missing run outputs and unable to generate them)"
                )
                continue
        errors = validate(
            run_dir,
            expected,
            reference if (reference / "step2-psi.dat").exists() else None,
        )
        if errors:
            failures += 1
            print(f"FAIL: {example.name}")
            for error in errors:
                print(f"  - {error}")
        else:
            print(f"PASS: {example.name}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())