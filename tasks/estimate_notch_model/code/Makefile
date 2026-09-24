include ../../shared/code/shell_functions.make

all: ../output/estimation_parents.parquet ../output/model_checks.csv ../output/estimates.csv \
	../output/recovery.csv ../output/pdf/model_fit.pdf

include ../../shared/code/generic.make

../output/estimation_parents.parquet: prepare_estimation_sample.R ../input/parent_opportunity_panel.parquet \
	../input/constituent_filing_panel.parquet Makefile | $(OOPR)
	$(R) $<

../output/model_checks.csv: test_notch_model.R notch_model.R ../output/estimation_parents.parquet Makefile | $(OOPR)
	$(R) $<

FIT_OUTPUTS := ../output/estimates.csv ../output/fit_moments.csv ../output/cell_fit.csv \
	../output/parameter_profiles.csv ../output/main_grid_cells.parquet

$(FIT_OUTPUTS): fit_notch_model.R notch_model.R ../output/estimation_parents.parquet \
	../output/model_checks.csv Makefile | $(OOPR)
	$(R) $<

../output/recovery.csv ../output/recovery_summary.csv: recover_parameters.R ../output/main_grid_cells.parquet \
	../output/estimates.csv Makefile | $(OOPR)
	$(R) $<

../output/pdf/model_fit.pdf: plot_model_fit.R ../output/cell_fit.csv ../output/estimates.csv Makefile | \
	$(OOPR) ../output/pdf
	$(R) $<

../input/parent_opportunity_panel.parquet: ../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	ln -sf $< $@
../input/constituent_filing_panel.parquet: ../../build_estimation_panels/output/constituent_filing_panel.parquet | ../input
	ln -sf $< $@
