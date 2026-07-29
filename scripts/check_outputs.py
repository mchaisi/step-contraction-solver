#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import re
from dataclasses import asdict, dataclass
from pathlib import Path

import numpy as np


LOG_RE = re.compile(r"n=\s*(\d+)\s+udiff=\s*([^\s]+).*?vdiff=\s*([^\s]+)")


@dataclass
class LogSummary:
    final_step: int | None
    final_residual: float | None
    best_residual: float | None
    maximum_residual: float | None
    finite_values: bool
    explicit_nonfinite_text: bool
    explosive_growth: bool
    zero_after_explosion: bool
    valid: bool


def parse_float(value: str) -> float:
    return float(value.replace("D", "E").replace("d", "e"))


def parse_log(path: Path, explosive_threshold: float = 1.0e20) -> LogSummary:
    history: list[tuple[int, float]] = []
    explicit_nonfinite = False

    for line in path.read_text(errors="ignore").splitlines():
        lower = line.lower()
        if any(token in lower for token in ("nan", "infinity", "overflow")):
            explicit_nonfinite = True
        match = LOG_RE.search(line)
        if not match:
            continue
        try:
            values = [parse_float(match.group(2)), parse_float(match.group(3))]
        except ValueError:
            explicit_nonfinite = True
            continue
        residual = max(abs(value) for value in values)
        history.append((int(match.group(1)), residual))

    finite_values = bool(history) and all(math.isfinite(item[1]) for item in history)
    finite_residuals = [item[1] for item in history if math.isfinite(item[1])]
    maximum = max(finite_residuals) if finite_residuals else None
    best = min(finite_residuals) if finite_residuals else None
    final_step = history[-1][0] if history else None
    final_residual = history[-1][1] if history else None
    explosive = maximum is not None and maximum >= explosive_threshold
    zero_after_explosion = bool(explosive and final_residual == 0.0)
    valid = bool(
        history
        and finite_values
        and not explicit_nonfinite
        and not explosive
        and not zero_after_explosion
    )

    return LogSummary(
        final_step=final_step,
        final_residual=final_residual,
        best_residual=best,
        maximum_residual=maximum,
        finite_values=finite_values,
        explicit_nonfinite_text=explicit_nonfinite,
        explosive_growth=explosive,
        zero_after_explosion=zero_after_explosion,
        valid=valid,
    )


def load_field(path: Path) -> np.ndarray:
    data = np.loadtxt(path)
    if data.ndim == 1:
        data = data.reshape(1, -1)
    if data.shape[1] < 3:
        raise ValueError(f"Expected at least three columns in {path}")
    return data


def summarize_field(path: Path) -> dict[str, object]:
    data = load_field(path)
    values = data[:, -1]
    finite = bool(np.isfinite(data).all())
    return {
        "path": str(path),
        "rows": int(data.shape[0]),
        "columns": int(data.shape[1]),
        "finite_values": finite,
        "minimum": float(np.nanmin(values)),
        "maximum": float(np.nanmax(values)),
        "max_abs": float(np.nanmax(np.abs(values))),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Check step-contraction solver outputs.")
    parser.add_argument("--log", type=Path, required=True, help="Run log produced by the solver.")
    parser.add_argument("--div", type=Path, help="Divergence output file.")
    parser.add_argument("--psi", type=Path, help="Streamfunction output file.")
    parser.add_argument(
        "--explosive-threshold",
        type=float,
        default=1.0e20,
        help="Residual magnitude above which a run is classified as explosive.",
    )
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON.")
    args = parser.parse_args()

    log_summary = parse_log(args.log, args.explosive_threshold)
    report: dict[str, object] = {"log": {"path": str(args.log), **asdict(log_summary)}}
    ok = log_summary.valid

    for label, path in (("divergence", args.div), ("streamfunction", args.psi)):
        if path is None:
            continue
        try:
            summary = summarize_field(path)
        except (OSError, ValueError) as error:
            summary = {"path": str(path), "error": str(error), "finite_values": False}
        report[label] = summary
        ok = ok and bool(summary.get("finite_values"))

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"log: {args.log}")
        for key, value in asdict(log_summary).items():
            print(f"  {key}: {value}")
        for label in ("divergence", "streamfunction"):
            if label not in report:
                continue
            print(f"{label}: {report[label].get('path')}")
            for key, value in report[label].items():
                if key != "path":
                    print(f"  {key}: {value}")

    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())