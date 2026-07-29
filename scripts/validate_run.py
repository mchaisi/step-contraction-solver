#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

import numpy as np

from check_outputs import load_field, parse_log, summarize_field


def close(actual: float, target: float, relative: float, absolute: float = 0.0) -> bool:
    return math.isclose(actual, target, rel_tol=relative, abs_tol=absolute)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def validate(
    run_dir: Path,
    expected_path: Path,
    reference_dir: Path | None = None,
) -> list[str]:
    expected = json.loads(expected_path.read_text())
    errors: list[str] = []
    threshold = float(expected.get("explosive_residual_threshold", 1.0e20))
    log_path = run_dir / "run.log"
    if not log_path.exists():
        return [f"Missing log: {log_path}"]

    log = parse_log(log_path, threshold)
    expected_valid = bool(expected["valid"])
    if expected_valid != log.valid:
        errors.append(f"Expected valid={expected_valid}, observed valid={log.valid}")

    if not expected_valid:
        if not (log.explosive_growth or log.explicit_nonfinite_text or log.zero_after_explosion):
            errors.append("Expected a detectable numerical failure, but none was found")
        return errors

    if log.final_step != int(expected["final_step"]):
        errors.append(f"Expected final step {expected['final_step']}, observed {log.final_step}")
    if log.final_residual is None or not close(
        log.final_residual,
        float(expected["final_residual"]),
        float(expected["residual_relative_tolerance"]),
    ):
        errors.append(
            f"Final residual {log.final_residual} is outside tolerance around "
            f"{expected['final_residual']}"
        )

    psi_path = run_dir / "step2-psi.dat"
    div_path = run_dir / "step2-div.dat"
    for path in (psi_path, div_path):
        if not path.exists():
            errors.append(f"Missing field: {path}")
    if errors:
        return errors

    psi = summarize_field(psi_path)
    div = summarize_field(div_path)
    if not psi["finite_values"]:
        errors.append("Streamfunction contains non-finite values")
    if not div["finite_values"]:
        errors.append("Divergence contains non-finite values")
    if float(div["max_abs"]) > float(expected["max_abs_divergence"]):
        errors.append(
            f"Maximum divergence {div['max_abs']} exceeds {expected['max_abs_divergence']}"
        )
    psi_tolerance = float(expected["psi_absolute_tolerance"])
    if not close(float(psi["minimum"]), float(expected["psi_min"]), 0.0, psi_tolerance):
        errors.append(f"Streamfunction minimum {psi['minimum']} is outside tolerance")
    if not close(float(psi["maximum"]), float(expected["psi_max"]), 0.0, psi_tolerance):
        errors.append(f"Streamfunction maximum {psi['maximum']} is outside tolerance")

    if reference_dir is not None:
        expected_hashes = {
            "step2-psi.dat": expected.get("reference_psi_sha256"),
            "step2-div.dat": expected.get("reference_div_sha256"),
        }
        for filename, expected_hash in expected_hashes.items():
            if expected_hash and sha256(reference_dir / filename) != expected_hash:
                errors.append(f"Archived reference checksum mismatch: {filename}")
        relative = float(expected["field_relative_tolerance"])
        absolute = float(expected["field_absolute_tolerance"])
        for filename in ("step2-psi.dat", "step2-div.dat"):
            actual = load_field(run_dir / filename)
            reference = load_field(reference_dir / filename)
            if actual.shape != reference.shape:
                errors.append(
                    f"{filename} shape {actual.shape} does not match reference {reference.shape}"
                )
                continue
            if not np.allclose(actual, reference, rtol=relative, atol=absolute, equal_nan=False):
                difference = float(np.max(np.abs(actual - reference)))
                errors.append(f"{filename} differs from reference; max absolute difference={difference}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate one solver run.")
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--expected", type=Path, required=True)
    parser.add_argument("--reference", type=Path)
    args = parser.parse_args()

    errors = validate(args.run_dir, args.expected, args.reference)
    if errors:
        print(f"FAIL: {args.expected}")
        for error in errors:
            print(f"  - {error}")
        return 1
    print(f"PASS: {args.expected}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())