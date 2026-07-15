SHELL := bash
.DELETE_ON_ERROR:

../input ../output ../temp slurmlogs:
	mkdir -p $@

run.sbatch: ../../setup_environment/code/run.sbatch | slurmlogs
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

UPSTREAM_TASKS := $(notdir $(patsubst %/code,%,$(wildcard ../../*/code)))

.PHONY: FORCE_UPSTREAM_CHECK
.PRECIOUS: ../../%

define UPSTREAM_OUTPUT_RULE
../../$(1)/output/%: FORCE_UPSTREAM_CHECK
	$$(MAKE) -C ../../$(1)/code ../output/$$*
endef

$(foreach task,$(UPSTREAM_TASKS),$(eval $(call UPSTREAM_OUTPUT_RULE,$(task))))

FORCE_UPSTREAM_CHECK:
