include ../../shared/code/shell_functions.make

all: ../output/R_packages.txt

include ../../shared/code/generic.make

../output/R_packages.txt: packages.R Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | $(OOPR)
	$(R) $<
