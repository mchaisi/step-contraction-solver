FC = gfortran
FFLAGS = -O2
LDLIBS = -llapack -lblas

.PHONY: all test validate figures clean

all: step

step: src/step.f
	$(FC) $(FFLAGS) -o step src/step.f $(LDLIBS)

test:
	python3 -m unittest tests/test_check_outputs.py

validate:
	python3 scripts/validate_examples.py

figures:
	python3 scripts/generate_publication_figures.py

clean:
	rm -f step
