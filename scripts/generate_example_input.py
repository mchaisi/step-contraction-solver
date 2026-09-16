#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path


METHOD_MAP = {
    "CD": "1",
    "UD": "2",
    "QUICK": "3",
}


def parse_example_name(name: str):
    tokens = name.split("_")
    result = {}
    if tokens[0].startswith("re"):
        result["RE"] = tokens[0][2:]
    if len(tokens) > 1:
        scheme = tokens[1].upper()
        if scheme in METHOD_MAP:
            result["METHOD"] = METHOD_MAP[scheme]
    for token in tokens:
        if token.startswith("dt"):
            value = token[2:]
            if value.startswith("1e"):
                result["DT"] = "1.0e-{}".format(value[2:])
            elif value.startswith("5e4"):
                result["DT"] = "5.0e-4"
    return result


def replace_keyword(lines, keyword, value):
    pattern = re.compile(r"^(%s)\b.*" % re.escape(keyword), re.IGNORECASE)
    replaced = False
    output = []
    for line in lines:
        if pattern.match(line):
            output.append("%s %s" % (keyword, value))
            replaced = True
        else:
            output.append(line)
    if not replaced:
        output.append("%s %s" % (keyword, value))
    return output


def load_default_input(default_input):
    return default_input.read_text().splitlines()


def write_run_input(run_input, lines):
    run_input.write_text("\n".join(lines) + "\n")


def main() -> int:
    import sys

    if len(sys.argv) != 3:
        raise SystemExit("Usage: generate_example_input.py EXAMPLE_DIR OUTPUT_STEP_DAT")

    example_dir = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    root = Path(__file__).resolve().parents[1]
    default_input = root / "input" / "step.dat"

    if not default_input.exists():
        raise FileNotFoundError(f"Default input file not found: {default_input}")

    lines = load_default_input(default_input)
    config = parse_example_name(example_dir.name)

    expected_path = example_dir / "expected.json"
    if expected_path.exists():
        expected = json.loads(expected_path.read_text())
        if expected.get("reynolds_number") is not None:
            config["RE"] = str(expected["reynolds_number"])
        if expected.get("scheme") is not None:
            config["METHOD"] = METHOD_MAP.get(expected["scheme"].upper(), config.get("METHOD", "2"))
        if expected.get("final_step") is not None:
            config["MAXSTEP"] = str(int(expected["final_step"]))

    for key, value in config.items():
        lines = replace_keyword(lines, key, value)

    write_run_input(output_path, lines)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
