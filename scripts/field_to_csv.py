#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert an x-y-scalar field to labelled CSV.")
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--name", default="field")
    args = parser.parse_args()

    data = np.loadtxt(args.input)
    if data.ndim == 1:
        data = data.reshape(1, -1)
    if data.shape[1] < 3 or not np.isfinite(data[:, :3]).all():
        raise SystemExit("Input must contain finite x, y, value columns")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    np.savetxt(
        args.output,
        data[:, [0, 1, data.shape[1] - 1]],
        delimiter=",",
        header=f"x,y,{args.name}",
        comments="",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())