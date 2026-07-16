SHELL := bash
.DELETE_ON_ERROR:

R = @. ../../../shell_functions.sh; run_r

ifneq (,$(findstring n,$(MAKEFLAGS)))
R := R
endif

../input ../output ../temp slurmlogs:
	mkdir -p $@

run.sbatch: ../../../setup_environment/code/run.sbatch | slurmlogs
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

UPSTREAM_TASKS := $(notdir $(patsubst %/code,%,$(wildcard ../../../*/code)))
AUDIT_TASKS := $(notdir $(patsubst %/code,%,$(wildcard ../../*/code)))

.PHONY: FORCE_UPSTREAM_CHECK
.PRECIOUS: ../../../% ../../%

define EXISTING_PRODUCTION_OUTPUT_RULE
.PHONY: CHECK_PRODUCTION_$(1)_$(notdir $(2))

CHECK_PRODUCTION_$(1)_$(notdir $(2)):
ifeq (,$(findstring n,$(MAKEFLAGS)))
	$$(MAKE) -C ../../../$(1)/code ../output/$(notdir $(2))
endif

$(2): | CHECK_PRODUCTION_$(1)_$(notdir $(2))
	@test -e "$$@"
endef

define EXISTING_AUDIT_OUTPUT_RULE
.PHONY: CHECK_AUDIT_$(1)_$(notdir $(2))

CHECK_AUDIT_$(1)_$(notdir $(2)):
ifeq (,$(findstring n,$(MAKEFLAGS)))
	$$(MAKE) -C ../../$(1)/code ../output/$(notdir $(2))
endif

$(2): | CHECK_AUDIT_$(1)_$(notdir $(2))
	@test -e "$$@"
endef

define MISSING_PRODUCTION_OUTPUT_RULE
../../../$(1)/output/%: FORCE_UPSTREAM_CHECK
	$$(MAKE) -C ../../../$(1)/code ../output/$$*
endef

define MISSING_AUDIT_OUTPUT_RULE
../../$(1)/output/%: FORCE_UPSTREAM_CHECK
	$$(MAKE) -C ../../$(1)/code ../output/$$*
endef

$(foreach task,$(UPSTREAM_TASKS),\
	$(foreach output,$(wildcard ../../../$(task)/output/*),\
		$(eval $(call EXISTING_PRODUCTION_OUTPUT_RULE,$(task),$(output)))))

$(foreach task,$(AUDIT_TASKS),\
	$(foreach output,$(wildcard ../../$(task)/output/*),\
		$(eval $(call EXISTING_AUDIT_OUTPUT_RULE,$(task),$(output)))))

$(foreach task,$(UPSTREAM_TASKS),\
	$(eval $(call MISSING_PRODUCTION_OUTPUT_RULE,$(task))))

$(foreach task,$(AUDIT_TASKS),\
	$(eval $(call MISSING_AUDIT_OUTPUT_RULE,$(task))))

FORCE_UPSTREAM_CHECK:
