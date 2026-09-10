SHELL := bash
.DELETE_ON_ERROR:
.NOTPARALLEL:

R := @. $(dir $(lastword $(MAKEFILE_LIST)))shell_functions.sh; run_r

# Indirection lets dry runs print recovery without recursively requesting it.
RECOVER = $(MAKE)
