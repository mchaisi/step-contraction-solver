# Step-contraction finite-volume solver

A preserved Fortran finite-volume projection solver for two-dimensional
incompressible Stokes or Navier--Stokes flow through a symmetric step
contraction. The code supports central differencing, first-order upwinding, and
QUICK treatments of convection.

The numerical source is preserved unchanged from the recovered 1995 source.
The modern repository adds reproducible builds, reference examples, validation,
documentation, tests, plotting, and ParaView/CSV export around that source.

## Repository contents

```text
src/                 current preserved numerical source
original/            immutable recovered 1995 source and input
input/               short default smoke-test input
examples/            inputs, archived reference outputs, acceptance criteria
scripts/             run, validation, plotting, VTK, and CSV utilities
tests/               automated numerical-safety parser tests
docs/                user, architecture, provenance, teaching, and extension docs
figures/             reproducibly generated manuscript figures
Makefile             build and validation entry points
run.sh               isolated default/custom execution
CHANGELOG.md          package-level change history
RELEASE_CHECKLIST.md  remaining release actions
```

## Quick start

Requirements:

- `gfortran` or another compatible Fortran compiler;
- BLAS and LAPACK development libraries;
- Python 3 with NumPy; Matplotlib is needed to regenerate figures.

The Makefile uses the following portable legacy-source flags by default:

```sh
gfortran -O2 -Wall -Wextra -std=legacy -ffixed-line-length-none \
  -o step src/step.f -llapack -lblas
```

Build and run the short smoke test:

```sh
make
./run.sh
```

The smoke-test outputs are written to `runs/default/` and checked for finite
residuals and fields.

Run a full archived configuration:

```sh
./run.sh examples/re20_quick/step.dat runs/re20_quick
python3 scripts/validate_run.py \
  --run-dir runs/re20_quick \
  --expected examples/re20_quick/expected.json \
  --reference examples/re20_quick/reference
```

Full benchmark runs use a dense pressure matrix and may take substantially
longer than the smoke test.

## Reproducibility

Validate the archived reference suite without compiling the solver:

```sh
make test
make validate
```

Reproduce every positive example on a compiler-equipped system:

```sh
scripts/reproduce_examples.sh
```

The examples cover:

- central, upwind, and QUICK comparisons at Re=20;
- upwind and QUICK at Re=200;
- central, upwind, and QUICK at Re=500;
- robust upwinding at Re=2000;
- two finite but non-steady QUICK runs at Re=2000;
- preserved central-difference failures at Re=200 and Re=2000 that demonstrate
  false convergence after explosive residual growth.

See [examples/README.md](examples/README.md) and
[docs/reproducibility.md](docs/reproducibility.md).

## Figure reproduction

All plotted residual histories and streamfunction fields used by the figure
script are stored under `examples/`:

```sh
make figures
```

This regenerates PNG and PDF versions in `figures/`.

## ParaView and spreadsheet export

The raw field format is whitespace-delimited `x`, `y`, value data. Convert a
streamfunction file to VTK:

```sh
python3 scripts/field_to_vtk.py \
  examples/re20_quick/reference/step2-psi.dat \
  re20-quick-streamfunction.vtk \
  --name streamfunction
```

Or to CSV:

```sh
python3 scripts/field_to_csv.py \
  examples/re20_quick/reference/step2-psi.dat \
  re20-quick-streamfunction.csv \
  --name streamfunction
```

In ParaView, open the VTK file and use point rendering directly or apply a
two-dimensional Delaunay filter before contouring.

## Documentation

- [User guide](docs/user-guide.md)
- [Architecture and data flow](docs/architecture.md)
- [Provenance and modernization record](docs/provenance.md)
- [Reproducibility and acceptance criteria](docs/reproducibility.md)
- [False-convergence failure](docs/false-convergence.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Teaching tutorial](docs/teaching-tutorial.md)
- [Extension guide](docs/extension-guide.md)

## Provenance

`src/step.f` and `original/step-1995.f` are byte-for-byte identical in this
release. Verify with:

```sh
cmp original/step-1995.f src/step.f
```

The repository's modern additions are packaging and tooling, not undocumented
changes to the numerical method.

## Known limitations

- The pressure Poisson matrix is dense and limits practical grid size.
- The contraction geometry is embedded in several routines.
- Checkpoints are compiler-dependent unformatted files.
- The legacy convergence test can print false convergence after overflow;
  always use the supplied validation tools.
- An explicit open-source license must be selected before public release.

## Citation and support

Support: `mchaisi@wsu.ac.za`.

Please cite the associated software article and the 1995 MSc dissertation once
the revised release metadata are finalised.