# Extension guide

The solver is intentionally focused on a symmetric step contraction. New
geometries should not be added by changing one boundary condition in isolation:
geometry assumptions occur in several coupled routines.

## Adding a convection scheme

1. Add and document a new `METHOD` value in `Input_Data`.
2. Implement the face interpolation consistently in the `UV_Stars` branches
   for both velocity components.
3. Add a low-Reynolds regression example and at least one stability test.
4. Compare divergence, residual history, and streamfunction against existing
   schemes.

## Adding a geometry

At minimum, review and update:

- `Matrix` for the pressure Poisson stencil and boundary cells;
- `bc` and `ic` for velocity conditions and initial state;
- `UV_Stars` where geometry-specific index ranges are used;
- `Calc_Psi`, `Calc_Div`, and output loops;
- grid-size expressions used for `A`, `p`, and `IPIV` allocation;
- reference examples and visualisation tests.

A safer long-term modernization would introduce an explicit geometry module
before adding cavity or sudden-expansion cases. That refactoring should be a
separate versioned development effort, because it changes more than the
packaging of the recovered solver.

## Adding output formats

Prefer post-processing converters when the raw numerical values are already
available. The supplied VTK and CSV scripts add interoperability without
changing the historical solver. Native Fortran output should be added only when
runtime performance or unavailable raw data justify it.