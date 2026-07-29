# Troubleshooting

## `gfortran: command not found`

Install a Fortran compiler and BLAS/LAPACK development packages using the
package manager for your operating system. Confirm with `gfortran --version`.

## Linker cannot find BLAS or LAPACK

The default link flags are `-llapack -lblas`. Install the development packages
or override `LDLIBS`, for example:

```sh
make LDLIBS="-L/path/to/libs -llapack -lblas"
```

## Input file cannot be opened

The executable reads `step.dat` from its current working directory. Use
`run.sh` or `scripts/run_example.sh`, which place the selected input in an
isolated run directory.

## `X must be divisible by 2`

Choose an even streamwise pressure-cell count.

## `Y must be divisible by gamma`

Choose a wall-normal pressure-cell count divisible by the contraction ratio.

## Checkpoint read fails or produces implausible output

Checkpoint files are unformatted compiler-dependent data. Only read a
checkpoint generated with the same grid, physical parameters, compiler
conventions, and source version. Comment out `CHECKIN` for a clean run.

## Run prints “converged” after rapidly increasing residuals

Treat the run as invalid. The recovered convergence logic can report zero after
floating-point overflow. Use `scripts/check_outputs.py`; it examines residual
history and output fields rather than trusting the final message.

## Residual does not reach `EPS`

This does not automatically mean the field is unusable. Inspect whether the
residual is decreasing, whether fields are finite, and whether divergence is
small. Compare with the archived examples. Do not weaken acceptance criteria
without documenting the scientific reason.

## ParaView does not recognise the solver output

Convert scalar outputs to legacy VTK using `scripts/field_to_vtk.py`. The raw
files are whitespace-delimited `x`, `y`, value triples, not native VTK files.