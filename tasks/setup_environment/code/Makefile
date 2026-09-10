include ../../shared/code/shell_functions.make

all: ../output/R_packages.txt

../output/R_packages.txt: packages.R Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<

include ../../shared/code/generic.make
