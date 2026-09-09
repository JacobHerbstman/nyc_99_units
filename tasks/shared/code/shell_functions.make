SHELL := bash
.DELETE_ON_ERROR:
.NOTPARALLEL:

R := @. $(dir $(lastword $(MAKEFILE_LIST)))shell_functions.sh; run_r
