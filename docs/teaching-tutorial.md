# Teaching tutorial: numerical diffusion and stability

## Learning goals

Students use one geometry and grid to compare central differencing, upwinding,
and QUICK. The exercise connects convection discretisation to residual history,
streamfunction structure, divergence, diffusion, and failure modes.

## Preparation

```sh
make
```

The archived references can be examined without rerunning the solver:

```sh
make validate
make figures
```

## Exercise

1. Compare `examples/re20_cd`, `examples/re20_ud`, and
   `examples/re20_quick`. Identify the only input keyword that changes the
   convection scheme.
2. Plot the three residual histories and compare their best and final values.
3. Open the streamfunction contour comparison and identify differences near
   the contraction.
4. Confirm that all three projected fields have maximum absolute divergence
   near machine precision.
5. Compare the Re=20 QUICK run with `examples/re500_quick`. Discuss why a field
   can be practically steady even when the nominal residual tolerance has not
   been reached.
6. Examine `docs/false-convergence.md` and explain why a final “converged” line
   is not sufficient evidence of numerical validity.

## Suggested assessment questions

- Why is first-order upwinding usually more robust and more diffusive?
- Why does the pressure projection produce small divergence even when the
  velocity residual remains above the target tolerance?
- Which diagnostics would you require before accepting a legacy CFD run?
- What parts of the current architecture would need to change to support a new
  geometry safely?