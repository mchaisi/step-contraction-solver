FC = gfortran
FFLAGS = -O2

all: step

step: src/step.f
	$(FC) $(FFLAGS) -o step src/step.f

clean:
	rm -f step
