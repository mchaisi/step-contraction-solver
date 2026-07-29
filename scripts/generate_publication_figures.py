#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import BoundaryNorm, ListedColormap

from check_outputs import parse_log


ROOT = Path(__file__).resolve().parents[1]
EXAMPLES = ROOT / "examples"
FIGURES = ROOT / "figures"
FIGURES.mkdir(exist_ok=True)

RUNS = {
    "cd20": "re20_cd",
    "ud20": "re20_ud",
    "quick20": "re20_quick",
    "quick500": "re500_quick",
    "quick2000": "re2000_quick_dt1e3",
    "quick2000small": "re2000_quick_dt5e4",
    "ud2000": "re2000_ud",
}


def reference(key: str, filename: str) -> Path:
    return EXAMPLES / RUNS[key] / "reference" / filename


def residual_history(key: str) -> tuple[np.ndarray, np.ndarray]:
    path = reference(key, "run.log")
    steps: list[int] = []
    residuals: list[float] = []
    import re

    pattern = re.compile(r"n=\s*(\d+)\s+udiff=\s*([^\s]+).*?vdiff=\s*([^\s]+)")
    for line in path.read_text(errors="ignore").splitlines():
        match = pattern.search(line)
        if match:
            steps.append(int(match.group(1)))
            residuals.append(
                max(
                    abs(float(match.group(2).replace("D", "E"))),
                    abs(float(match.group(3).replace("D", "E"))),
                )
            )
    return np.asarray(steps), np.asarray(residuals)


def read_field(key: str) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    data = np.loadtxt(reference(key, "step2-psi.dat"))
    x = np.unique(data[:, 0])
    y = np.unique(data[:, 1])
    field = np.full((len(y), len(x)), np.nan)
    x_index = {value: index for index, value in enumerate(x)}
    y_index = {value: index for index, value in enumerate(y)}
    for x_value, y_value, psi_value in data:
        field[y_index[y_value], x_index[x_value]] = psi_value
    return x, y, field


def savefig(name: str) -> None:
    for extension in ("pdf", "png"):
        plt.savefig(FIGURES / f"{name}.{extension}", bbox_inches="tight", dpi=300)
    plt.close()


plt.rcParams.update(
    {
        "font.size": 9,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "figure.dpi": 140,
    }
)

# Re=20 residual histories.
plt.figure(figsize=(5.8, 3.4))
for key, label in (("cd20", "CD"), ("ud20", "UD"), ("quick20", "QUICK")):
    steps, residuals = residual_history(key)
    plt.semilogy(steps, residuals, label=label, linewidth=1.2)
plt.axhline(1e-8, color="0.4", linestyle=":", linewidth=1, label=r"$10^{-8}$ tolerance")
plt.xlabel("Time step")
plt.ylabel(r"max($u$ residual, $v$ residual)")
plt.title("Residual histories at Re=20")
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend(frameon=False, ncol=2)
savefig("re20_residual_histories")

# Re=20 streamfunction contours.
fields: list[np.ndarray] = []
for key in ("cd20", "ud20", "quick20"):
    x, y, field = read_field(key)
    fields.append(field)
finite = np.concatenate([field[np.isfinite(field)] for field in fields])
levels = np.linspace(np.nanmin(finite), np.nanmax(finite), 17)
figure, axes = plt.subplots(1, 3, figsize=(7.2, 2.65), sharex=True, sharey=True)
for axis, field, title in zip(axes, fields, ("CD", "UD", "QUICK")):
    contour = axis.contour(x, y, field, levels=levels, colors="black", linewidths=0.45)
    axis.contourf(x, y, field, levels=levels, cmap="viridis", alpha=0.9)
    axis.set_title(title)
    axis.set_xlabel("$x$")
    axis.set_aspect("equal", adjustable="box")
axes[0].set_ylabel("$y$")
figure.colorbar(contour, ax=axes, shrink=0.78, label=r"$\psi$")
figure.suptitle("Streamfunction contours at Re=20", y=1.03)
savefig("re20_streamfunction_contours")

# QUICK residual histories by Reynolds number.
plt.figure(figsize=(5.8, 3.4))
for key, label in (
    ("quick20", r"Re=20"),
    ("quick500", r"Re=500"),
    ("quick2000", r"Re=2000, $\Delta t=10^{-3}$"),
    ("quick2000small", r"Re=2000, $\Delta t=5\times10^{-4}$"),
):
    steps, residuals = residual_history(key)
    plt.semilogy(steps, residuals, label=label, linewidth=1.15)
plt.axhline(1e-8, color="0.4", linestyle=":", linewidth=1)
plt.xlabel("Time step")
plt.ylabel(r"max($u$ residual, $v$ residual)")
plt.title("QUICK residual histories")
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend(frameon=False, fontsize=8)
savefig("quick_reynolds_residual_histories")

# Reproduced-run outcome map derived from archived machine-readable evidence.
schemes = ["CD", "UD", "QUICK"]
reynolds = [20, 200, 500, 2000]
status_order = {"not_run": 0, "near_steady": 1, "finite_nonsteady": 2, "failed": 3}
status_labels = {
    "not_run": "not run",
    "near_steady": "near steady",
    "finite_nonsteady": "finite non-steady",
    "failed": "failed",
}
outcomes: dict[tuple[str, int], str] = {}
for expected_path in sorted(EXAMPLES.glob("*/expected.json")):
    expected = json.loads(expected_path.read_text())
    key = (expected["scheme"], int(expected["reynolds_number"]))
    status = expected["classification"]
    previous = outcomes.get(key, "not_run")
    if status_order[status] > status_order[previous]:
        outcomes[key] = status
colors = ["#eeeeee", "#3b8f5a", "#e6a23c", "#c94c4c"]
grid = np.zeros((len(reynolds), len(schemes)))
labels = [[status_labels["not_run"] for _ in schemes] for _ in reynolds]
for (scheme, reynolds_number), status in outcomes.items():
    row = reynolds.index(reynolds_number)
    column = schemes.index(scheme)
    grid[row, column] = status_order[status]
    labels[row][column] = status_labels[status]
figure, axis = plt.subplots(figsize=(5.6, 3.2))
norm = BoundaryNorm(np.arange(-0.5, 4.5, 1), len(colors))
axis.imshow(grid, cmap=ListedColormap(colors), norm=norm, aspect="auto")
axis.set_xticks(range(len(schemes)), schemes)
axis.set_yticks(range(len(reynolds)), [str(value) for value in reynolds])
axis.set_xlabel("Convection scheme")
axis.set_ylabel("Reynolds number")
axis.set_title("Reproduced-run outcomes")
for row in range(len(reynolds)):
    for column in range(len(schemes)):
        axis.text(column, row, labels[row][column].replace(" ", "\n"), ha="center", va="center", fontsize=8)
for spine in axis.spines.values():
    spine.set_visible(True)
savefig("outcome_map")

# Ensure parsing remains valid for each plotted run.
for key in RUNS:
    summary = parse_log(reference(key, "run.log"))
    if not summary.final_step:
        raise SystemExit(f"No residual history found for {key}")