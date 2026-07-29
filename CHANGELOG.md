# Changelog

All notable changes to the packaged software are recorded here. The numerical
source in `src/step.f` is preserved from the recovered 1995 source; changes
listed below concern packaging, documentation, validation, and post-processing
unless explicitly stated otherwise.

## Unreleased

- Added a reproducible build using `Makefile`.
- Added isolated execution through `run.sh` and `scripts/run_example.sh`.
- Added five benchmark inputs with archived reference logs, streamfunction
  fields, divergence fields, and machine-readable acceptance criteria.
- Added automated validation of archived references and newly generated runs.
- Added VTK and CSV conversion for scalar field outputs.
- Added architecture, user, provenance, troubleshooting, teaching, and
  extension documentation.
- Added tests for log parsing and false-convergence detection.
- Added scripts and archived inputs needed to regenerate manuscript figures.

## 1995 recovered source

- Original finite-volume projection solver developed for the MSc dissertation
  *Numerical Simulation of a Contraction Flow Using the Finite Volume Method*.