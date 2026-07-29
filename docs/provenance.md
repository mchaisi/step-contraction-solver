# Provenance and modernization record

## Origin

`original/step-1995.f` is the recovered solver associated with Mosa Chaisi's
1995 MSc dissertation, *Numerical Simulation of a Contraction Flow Using the
Finite Volume Method*. `original/step-1995.dat` is an archived input file from
the same source collection.

## Numerical source comparison

At preparation of this release, `src/step.f` is byte-for-byte identical to
`original/step-1995.f`. No numerical formula, boundary condition, convergence
criterion, or output routine has been silently modernised.

Verify this claim from the repository root:

```sh
cmp original/step-1995.f src/step.f
```

An exit status of zero means the files are identical.

## What has changed

Modernization is deliberately confined to the software package around the
legacy source:

- reproducible compilation through `Makefile`;
- isolated runs through shell scripts;
- documented inputs, outputs, architecture, and troubleshooting;
- preserved benchmark inputs and reference outputs;
- finite-value, residual, divergence, and field-comparison checks;
- Python plotting and VTK/CSV conversion;
- automated tests and continuous-integration configuration.

These additions do not alter the solver's numerical implementation.

## Future source changes

Any future modification to `src/step.f` should be recorded in `CHANGELOG.md`
and accompanied by:

1. a focused explanation of the change;
2. a regression comparison against the archived examples;
3. updated acceptance values where scientifically justified; and
4. retention of `original/step-1995.f` as the immutable historical baseline.