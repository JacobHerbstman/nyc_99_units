SHELL := bash
.DELETE_ON_ERROR:

../input ../output ../temp slurmlogs:
	mkdir -p $@

run.sbatch: ../../setup_environment/code/run.sbatch | slurmlogs
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

UPSTREAM_TASKS := $(notdir $(patsubst %/code,%,$(wildcard ../../*/code)))

.PRECIOUS: ../../%

define UPSTREAM_OUTPUT_RULE
../../$(1)/output/%:
	$$(MAKE) -C ../../$(1)/code ../output/$$*
endef

$(foreach task,$(UPSTREAM_TASKS),\
	$(eval $(call UPSTREAM_OUTPUT_RULE,$(task))))
