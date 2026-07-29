# Reproducibility and acceptance criteria

## Evidence model

Each archived example binds together:

1. the exact `step.dat` input;
2. the complete console residual log;
3. the streamfunction field;
4. the divergence field;
5. machine-readable expected values and tolerances;
6. SHA-256 checksums for the archived fields.

This prevents figures or manuscript values from being detached from the run
that produced them.

## Archived example matrix

| Example | Method | Re | dt | Steps | Final residual | Max divergence | Classification |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| `re20_cd` | Central | 20 | 1e-3 | 7000 | 5.1363e-6 | 1.11137e-12 | finite, near steady |
| `re20_ud` | Upwind | 20 | 1e-3 | 7000 | 5.5067e-6 | 1.10631e-12 | finite, near steady |
| `re20_quick` | QUICK | 20 | 1e-3 | 7000 | 5.8821e-6 | 1.12967e-12 | finite, near steady |
| `re200_ud` | Upwind | 200 | 1e-3 | 7000 | 3.6231e-6 | 7.21041e-13 | finite, near steady |
| `re200_quick` | QUICK | 200 | 1e-3 | 7000 | 1.1938e-5 | 7.05174e-13 | finite, near steady |
| `re500_cd` | Central | 500 | 1e-3 | 3500 | 6.6945e-1 | 6.57768e-13 | finite, non-steady |
| `re500_ud` | Upwind | 500 | 1e-3 | 10000 | 1.1193e-6 | 6.90116e-13 | finite, near steady |
| `re500_quick` | QUICK | 500 | 1e-3 | 10000 | 3.1156e-6 | 6.55505e-13 | finite, decreasing |
| `re2000_ud` | Upwind | 2000 | 1e-2 | 3500 | 2.6232e-8 | 4.33436e-12 | finite, robust |
| `re2000_quick_dt1e3` | QUICK | 2000 | 1e-3 | 7000 | 5.9801e-1 | 1.10908e-12 | finite, non-steady |
| `re2000_quick_dt5e4` | QUICK | 2000 | 5e-4 | 10000 | 9.8922e-1 | 7.07172e-13 | finite, non-steady |
| `known_failure_cd_re200` | Central | 200 | 1e-2 | 28 | false zero | not accepted | explosive failure |
| `known_failure_cd_re2000` | Central | 2000 | 1e-3 | 611 | false zero | not accepted | explosive failure |

## Validation rules

Positive examples must satisfy all of the following:

- complete residual history is parseable and finite;
- no explicit `NaN`, `Infinity`, or overflow text is present;
- residual history does not exceed the explosive-growth threshold;
- final step and residual agree with example-specific tolerances;
- streamfunction and divergence fields contain only finite values;
- maximum absolute divergence is below the configured limit;
- streamfunction range agrees with the archived behaviour;
- newly produced fields agree with references within the configured absolute
  and relative tolerances.

The negative examples pass validation only when the checker detects a failure.
Their residuals grow beyond `1e20` and then collapse to zero immediately before
the program prints a misleading convergence message.

## Commands

Validate archived data and checksums:

```sh
python3 scripts/validate_examples.py
```

Run and compare one example:

```sh
scripts/run_example.sh examples/re20_cd runs/re20_cd
python3 scripts/validate_run.py \
  --run-dir runs/re20_cd \
  --expected examples/re20_cd/expected.json \
  --reference examples/re20_cd/reference
```

Run every positive example:

```sh
scripts/reproduce_examples.sh
```

## Platform variation

The pressure solve uses BLAS/LAPACK and the simulation performs many floating-
point operations. Small differences between compilers and libraries are
expected. Acceptance therefore uses scientifically chosen tolerances rather
than requiring byte-identical newly generated fields. Archived field checksums
remain exact so accidental modification of the reference data is detectable.

## Current verification boundary

Archived-data validation, tests, figure generation, and VTK/CSV conversion are
platform-independent and run in Python. Building and rerunning the Fortran
solver additionally requires a compiler and BLAS/LAPACK. GitHub Actions installs
those dependencies and performs a build plus smoke test.