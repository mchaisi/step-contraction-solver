# Reproducible benchmark examples

Each example contains the exact `step.dat` input and archived reference outputs
used during manuscript preparation. Positive examples include a full residual
log, streamfunction field, divergence field, and `expected.json` acceptance
criteria. The negative example preserves a false-convergence failure log.

| Example | Scheme | Re | Steps | Expected classification |
| --- | --- | ---: | ---: | --- |
| `re20_cd` | Central differencing | 20 | 7000 | finite, near steady |
| `re20_ud` | Upwind | 20 | 7000 | finite, near steady |
| `re20_quick` | QUICK | 20 | 7000 | finite, near steady |
| `re200_ud` | Upwind | 200 | 7000 | finite, near steady |
| `re200_quick` | QUICK | 200 | 7000 | finite, near steady |
| `re500_cd` | Central differencing | 500 | 3500 | finite, non-steady |
| `re500_ud` | Upwind | 500 | 10000 | finite, near steady |
| `re500_quick` | QUICK | 500 | 10000 | finite, decreasing/near steady field |
| `re2000_ud` | Upwind | 2000 | 3500 | finite, robust |
| `re2000_quick_dt1e3` | QUICK | 2000 | 7000 | finite, non-steady |
| `re2000_quick_dt5e4` | QUICK | 2000 | 10000 | finite, non-steady |
| `known_failure_cd_re200` | Central differencing | 200 | 28 | explosive growth followed by false zero residual |
| `known_failure_cd_re2000` | Central differencing | 2000 | 611 | explosive growth followed by false zero residual |

Validate the archived references:

```sh
python3 scripts/validate_examples.py
```

Rerun a positive example after building:

```sh
scripts/run_example.sh examples/re20_quick runs/re20_quick
python3 scripts/validate_run.py \
  --run-dir runs/re20_quick \
  --expected examples/re20_quick/expected.json \
  --reference examples/re20_quick/reference
```

The reference outputs are evidence from the archived reproduction campaign,
not universal benchmark constants. Acceptance tolerances allow small compiler
and BLAS/LAPACK variation while still checking the reported physical and
numerical behaviour.

The `re500_quick` reference directory also preserves the 7000-step field and
log used to quantify the small field change between 7000 and 10000 steps.