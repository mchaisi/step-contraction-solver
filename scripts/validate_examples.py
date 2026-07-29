#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from validate_run import validate


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    failures = 0
    for expected in sorted((ROOT / "examples").glob("*/expected.json")):
        example = expected.parent
        reference = example / "reference"
        errors = validate(reference, expected, reference if (reference / "step2-psi.dat").exists() else None)
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