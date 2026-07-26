#!/bin/bash
set -e

# Copy input file to current directory (required by the solver)
cp input/step.dat step.dat

# Run the solver
./step

# Clean up the temporary input file copy
rm step.dat










