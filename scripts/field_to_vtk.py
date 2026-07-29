#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert an x-y-scalar field to legacy VTK.")
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--name", default="field", help="Scalar name shown in ParaView")
    args = parser.parse_args()

    data = np.loadtxt(args.input)
    if data.ndim == 1:
        data = data.reshape(1, -1)
    if data.shape[1] < 3 or not np.isfinite(data[:, :3]).all():
        raise SystemExit("Input must contain finite x, y, value columns")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w") as output:
        output.write("# vtk DataFile Version 3.0\n")
        output.write(f"Converted from {args.input.name}\n")
        output.write("ASCII\n")
        output.write("DATASET POLYDATA\n")
        output.write(f"POINTS {len(data)} double\n")
        for x_value, y_value in data[:, :2]:
            output.write(f"{x_value:.16e} {y_value:.16e} 0.0\n")
        output.write(f"VERTICES {len(data)} {2 * len(data)}\n")
        for index in range(len(data)):
            output.write(f"1 {index}\n")
        output.write(f"POINT_DATA {len(data)}\n")
        output.write(f"SCALARS {args.name} double 1\n")
        output.write("LOOKUP_TABLE default\n")
        for value in data[:, -1]:
            output.write(f"{value:.16e}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())