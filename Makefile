FC = gfortran
FFLAGS = -O2
LDLIBS = -llapack -lblas

all: step

step: src/step.f
	$(FC) $(FFLAGS) -o step src/step.f $(LDLIBS)

clean:
	rm -f step
