# Step Contraction Solver

This repository contains a Fortran 90 implementation of a finite-volume solver for 2-D Stokes and Navier-Stokes flow through a symmetric step contraction. The program reads a parameter file, solves the pressure-correction system, and writes field and diagnostic output files for subsequent analysis.

## Code Ocean reproducibility

This project is organized for reproducible execution in Code Ocean:

- The build step is handled by the provided Makefile.
- The default execution step is handled by the provided run script.
- A sample input file is included in the repository so the workflow can be reproduced without additional setup.
- The solver writes output files into the workspace root, making results easy to inspect after execution.

## Repository contents

- `src/step.f`: main Fortran source code.
- `input/step.dat`: example input parameters.
- `Makefile`: builds the executable named `step` using `gfortran`.
- `run.sh`: executes the solver with the bundled input file.

## Requirements

- A Fortran compiler such as `gfortran`
- A Unix-like shell (`bash`)

## Build

From the project root, run:

```bash
make
```

This produces the executable `step`.

## Run

To run the solver with the bundled example input:

```bash
./run.sh
```

The script runs:

```bash
./step < input/step.dat
```

## Expected outputs

The solver generates output files such as:

- `step2-u.dat`
- `step2-v.dat`
- `step2-p.dat`
- `step2-psi.dat`
- `step2-div.dat`
- `Separation2.PsiMax`
- `Wall2dws.vorticity`

## Clean build artifacts

To remove the generated executable:

```bash
make clean
```

## Notes

The input file uses keyword-value pairs in uppercase, as shown in `input/step.dat`. You can modify the mesh size, timestep, Reynolds number, and output filenames by editing that file.

