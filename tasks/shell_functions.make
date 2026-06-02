R = @. ../../shell_functions.sh; run_r

ifneq (,$(findstring n,$(MAKEFLAGS)))
R := R
endif
