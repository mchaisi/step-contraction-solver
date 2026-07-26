# Step Contraction Solver

A Fortran finite-volume solver for 2-D Stokes and Navier–Stokes flow through a symmetric step contraction. The code reads a parameter file, solves the pressure-correction system, and writes field and diagnostic output files.

## Overview

This repository contains source code and a reproducible example input for the step contraction solver. It is configured to build with `gfortran` and run using the provided `run.sh` wrapper.

## Requirements

- `gfortran` or a compatible Fortran compiler
- LAPACK and BLAS libraries (`-llapack -lblas`)
- Unix-like shell (`bash`)

## Build

From the project root, run:

```bash
make
```

This produces the executable `step`.

## Run

Run the solver with the bundled example input:

```bash
./run.sh
```

The script executes:

```bash
./step < input/step.dat
```

## Expected outputs

Example outputs created by the solver include:

- `step2-u.dat`
- `step2-v.dat`
- `step2-p.dat`
- `step2-psi.dat`
- `step2-div.dat`
- `Separation2.PsiMax`
- `Wall2dws.vorticity`

These files are generated at runtime and should not be committed to the repository.

## Repository structure

- `src/step.f` — main Fortran source file
- `input/step.dat` — example parameter input file
- `Makefile` — build instructions
- `run.sh` — execution wrapper
- `LICENSE.txt` — software license
- `README.md` — project documentation
- `.gitignore` — files to ignore in version control

## Notes

The input file uses uppercase keyword/value pairs as shown in `input/step.dat`. Modify parameters such as mesh size, timestep, Reynolds number, and output filenames by editing that file.

## Clean

Remove the compiled executable using:

```bash
make clean
```

