include ../../shared/code/shell_functions.make

OUTPUTS := ../output/pdf/parent_bunching_2019_2022.pdf ../output/pdf/parent_bunching_both_periods.pdf

all: $(OUTPUTS)

include ../../shared/code/generic.make

$(OUTPUTS): plot_bunching_reveal.R ../input/parent_opportunity_panel.parquet Makefile | $(OOPR) ../output/pdf
	$(R) $<

../input/parent_opportunity_panel.parquet: ../../build_estimation_panels/output/parent_opportunity_panel.parquet \
	| ../input
	ln -sf $< $@
