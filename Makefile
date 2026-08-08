FC = gfortran
FFLAGS = -O2
LDLIBS = -llapack -lblas

.PHONY: all clean figures validate

all: step

step: src/step.f
	$(FC) $(FFLAGS) -o step src/step.f $(LDLIBS)

clean:
	rm -f step

figures:
	python3 scripts/generate_publication_figures.py

validate:
	python3 scripts/validate_examples.py
