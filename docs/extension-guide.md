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

### Concrete sudden-expansion adaptation

The current input deck exposes `XM`, `H`, `X`, `Y`, and `GAMMA`, but `GAMMA`
alone does not describe an arbitrary geometry. For a sudden expansion, use the
same staggered-grid convention and make the following changes together:

1. Define the upstream and downstream active-cell ranges and their interface
   in one geometry table. Keep the pressure-cell ordering documented beside
   the table so matrix and right-hand-side indices remain identical.
2. Replace the contraction-specific rows in `Matrix` with the five-point
   finite-volume stencil for the new active-cell mask. Omit solid neighbours
   and use the corresponding one-sided pressure-flux treatment at the step.
3. Update `bc` for inlet, outlet, no-slip walls, and the expansion shoulder.
   Decide explicitly whether the inlet is the existing symmetry-centre profile
   or a prescribed no-slip channel profile.
4. Update the geometry-dependent ranges in `UV_Stars`, `Rhs_Column`,
   `UV_n_plus_1`, `Calc_Psi`, `Calc_Div`, and the output routines. These are
   coupled because the arrays store face values while the pressure solve uses
   active cell values.
5. Add a low-Reynolds-number reference run with archived residual, divergence,
   and field outputs before attempting higher-Reynolds-number cases.

### Concrete lid-driven cavity adaptation

A cavity case requires a rectangular active-cell mask, zero normal velocity on
all walls, and a prescribed tangential velocity on the lid. It is therefore a
useful teaching extension, but it is not obtained by changing `GAMMA` in the
current program. The implementation should replace the inlet/outlet branches
in `bc`, remove the contraction link-cell rows in `Matrix`, and revise the
predictor and diagnostic boundary ranges. The pressure reference constraint
`A(1,1)=1` and the staggered pressure/velocity indexing must be retained.

For either example, the repository validation contract is finite fields,
bounded divergence, and a documented expected classification in
`examples/<name>/expected.json`, with residual behaviour appropriate to the
chosen case.

## Adding output formats

Prefer post-processing converters when the raw numerical values are already
available. The supplied VTK and CSV scripts add interoperability without
changing the historical solver. Native Fortran output should be added only when
runtime performance or unavailable raw data justify it.