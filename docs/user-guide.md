# User guide

## Purpose

The solver computes two-dimensional incompressible Stokes or Navier--Stokes
flow through the upper half of a symmetric step-contraction channel. It uses a
finite-volume projection method and offers central differencing, first-order
upwinding, and QUICK discretisations for convection.

## Installation

Required system software:

- a Fortran compiler such as `gfortran`;
- BLAS and LAPACK development libraries;
- a Unix-like shell for the supplied run scripts;
- Python 3 with NumPy for validation and post-processing.

Build from the repository root:

```sh
make
```

The equivalent compiler invocation is:

```sh
gfortran -O2 -Wall -Wextra -std=legacy -ffixed-line-length-none \
  -o step src/step.f -llapack -lblas
```

## First run

Run the short smoke test:

```sh
./run.sh
```

Outputs are written to `runs/default/`. To select another input and run
directory:

```sh
./run.sh examples/re20_quick/step.dat runs/re20_quick
```

## Input parameters

The legacy executable always reads a file named `step.dat` in its working
directory. `run.sh` and `scripts/run_example.sh` manage that detail.

| Keyword | Meaning | Constraints or notes |
| --- | --- | --- |
| `METHOD` | Numerical model/scheme | `0`: Stokes; `1`: central; `2`: upwind; `3`: QUICK |
| `XM` | Channel half-length | Positive real value |
| `H` | Upstream half-height | Positive real value |
| `X` | Streamwise pressure cells | Must be divisible by 2 |
| `Y` | Wall-normal pressure cells | Must be divisible by `GAMMA` |
| `DT` | Time step | Stability depends on scheme and Reynolds number |
| `EPS` | Stopping tolerance | Applied to printed velocity-change residual |
| `NU` | Kinematic-viscosity parameter | Used directly for Stokes runs |
| `RE` | Reynolds number | Used for Navier--Stokes runs |
| `GAMMA` | Contraction ratio | Integer used by the grid mapping |
| `MAXSTEP` | Maximum time steps | Run terminates when reached |
| `IINFO` | Residual print interval | Positive integer |
| `CHECKIN` | Optional checkpoint input | Leave commented for a clean run |
| `CHECKOUT` | Optional checkpoint output | Leave commented unless restart data are needed |
| `UOUT`, `VOUT`, `POUT` | Velocity/pressure filenames | Velocity and pressure writers are disabled in the recovered main program |
| `PSIOUT` | Streamfunction filename | Written at run completion |
| `DIVOUT` | Divergence filename | Written at run completion |
| `SEPPSIMAX` | Separation diagnostic filename | Associated call is disabled in the recovered main program |
| `WVORT` | Wall-vorticity filename | Written at run completion |

## Outputs

- `run.log`: time-step residual history and termination message.
- `step2-psi.dat`: columns `x`, `y`, and streamfunction.
- `step2-div.dat`: columns `x`, `y`, and discrete divergence.
- wall-vorticity file selected by `WVORT`.
- optional checkpoint selected by `CHECKOUT`.

The program can print an apparent convergence message after floating-point
overflow because non-finite comparisons can collapse the reported residual to
zero. Never use the final message alone as evidence of a valid run.

## Validation

Validate all archived references:

```sh
make validate
```

Validate a newly generated run against its example criteria:

```sh
python3 scripts/validate_run.py \
  --run-dir runs/re20_quick \
  --expected examples/re20_quick/expected.json
```

## Post-processing

Convert a scalar field to legacy VTK for ParaView:

```sh
python3 scripts/field_to_vtk.py \
  runs/re20_quick/step2-psi.dat \
  runs/re20_quick/step2-psi.vtk \
  --name streamfunction
```

Convert the same file to a labelled CSV:

```sh
python3 scripts/field_to_csv.py \
  runs/re20_quick/step2-psi.dat \
  runs/re20_quick/step2-psi.csv \
  --name streamfunction
```

Regenerate the manuscript figures from archived examples:

```sh
make figures
```

## Troubleshooting

See [troubleshooting.md](troubleshooting.md) for build, input, stability, and
checkpoint problems.