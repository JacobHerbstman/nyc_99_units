include ../../shared/code/shell_functions.make

all: ../output/estimation_parents.parquet ../output/model_checks.csv ../output/estimates.csv \
	../output/recovery.csv ../output/model_fit.png

include ../../shared/code/generic.make

../output/estimation_parents.parquet: prepare_estimation_sample.R ../input/parent_opportunity_panel.parquet \
	../input/constituent_filing_panel.parquet ../../shared/code/scale_shape_helpers.R \
	../../shared/code/write_data_report.R Makefile | $(OOPR)
	$(R) $<

../output/model_checks.csv: test_notch_model.R notch_model.R ../output/estimation_parents.parquet \
	../../shared/code/write_data_report.R Makefile | $(OOPR)
	$(R) $<

FIT_OUTPUTS := ../output/parameter_grid.parquet ../output/estimates.csv ../output/fit_moments.csv \
	../output/cell_fit.csv ../output/parameter_profiles.csv ../output/main_grid_cells.parquet \
	../output/main_observed_cells.csv

$(FIT_OUTPUTS): fit_notch_model.R notch_model.R ../output/estimation_parents.parquet \
	../output/model_checks.csv ../../shared/code/write_data_report.R Makefile | $(OOPR)
	$(R) $<

../output/recovery.csv ../output/recovery_summary.csv: recover_parameters.R ../output/main_grid_cells.parquet \
	../output/main_observed_cells.csv ../output/estimates.csv ../../shared/code/write_data_report.R \
	Makefile | $(OOPR)
	$(R) $<

../output/model_fit.png ../output/pdf/model_fit.pdf ../output/parameter_profiles.png \
	../output/pdf/parameter_profiles.pdf: plot_model_fit.R ../output/cell_fit.csv \
	../output/parameter_profiles.csv ../output/estimates.csv Makefile | $(OOPR) ../output/pdf
	$(R) $<

../input/parent_opportunity_panel.parquet: ../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	ln -sf $< $@
../input/constituent_filing_panel.parquet: ../../build_estimation_panels/output/constituent_filing_panel.parquet | ../input
	ln -sf $< $@
