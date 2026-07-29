# False convergence after overflow

Some unstable central-difference runs show rapidly increasing residuals over
many orders of magnitude and then print zero residuals followed by a convergence
message. This is not physical convergence. It is a legacy numerical-safety
failure associated with floating-point overflow and the way the maximum-change
test handles non-finite values.

The validation tools therefore classify a run using the complete residual
history and the generated fields. A run is rejected when any of the following
is observed:

- `NaN`, `Infinity`, or explicit overflow text;
- non-finite field values;
- residual magnitude above the configured safety threshold;
- a collapse to zero immediately after explosive residual growth;
- failure of example-specific residual, divergence, or field tolerances.

This diagnostic is intentionally independent of the final line printed by the
Fortran program.