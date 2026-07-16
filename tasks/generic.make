SHELL := bash
.DELETE_ON_ERROR:

../input ../output ../temp slurmlogs:
	mkdir -p $@

run.sbatch: ../../setup_environment/code/run.sbatch | slurmlogs
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

UPSTREAM_TASKS := $(notdir $(patsubst %/code,%,$(wildcard ../../*/code)))

.PHONY: FORCE_UPSTREAM_CHECK
.PRECIOUS: ../../%

define EXISTING_UPSTREAM_OUTPUT_RULE
.PHONY: CHECK_UPSTREAM_$(1)_$(notdir $(2))

CHECK_UPSTREAM_$(1)_$(notdir $(2)):
ifeq (,$(findstring n,$(MAKEFLAGS)))
	$$(MAKE) -C ../../$(1)/code ../output/$(notdir $(2))
endif

$(2): | CHECK_UPSTREAM_$(1)_$(notdir $(2))
	@test -e "$$@"
endef

define MISSING_UPSTREAM_OUTPUT_RULE
../../$(1)/output/%: FORCE_UPSTREAM_CHECK
	$$(MAKE) -C ../../$(1)/code ../output/$$*
endef

$(foreach task,$(UPSTREAM_TASKS),\
	$(foreach output,$(wildcard ../../$(task)/output/*),\
		$(eval $(call EXISTING_UPSTREAM_OUTPUT_RULE,$(task),$(output)))))

$(foreach task,$(UPSTREAM_TASKS),\
	$(eval $(call MISSING_UPSTREAM_OUTPUT_RULE,$(task))))

FORCE_UPSTREAM_CHECK:
