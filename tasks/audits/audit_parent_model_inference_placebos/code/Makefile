SHELL := bash
include ../../../shell_functions.make

TRAINING_START_YEAR := 2019
TRAINING_END_YEAR := 2023
PSEUDO_START_YEAR := 2020
PSEUDO_END_YEAR := 2023
TRAINING_ENDPOINTS := 2022,2023
POST_YEAR := 2025
MIN_UNITS := 6
MIN_CATEGORY_ROWS := 30
THRESHOLD_MIN := 80
THRESHOLD_MAX := 120
THRESHOLD_UNITS := 100
COUNTERFACTUAL_MAX_UNITS := 400
BOOTSTRAP_REPS := 499
BOOTSTRAP_SEED := 9901
INTERVAL_LOWER := 0.025
INTERVAL_UPPER := 0.975

all: ../output/parent_model_pseudo_policy_years.csv \
	../output/parent_model_threshold_placebos.csv \
	../output/parent_model_leave_one_year_out.csv \
	../output/parent_model_training_endpoints.csv \
	../output/parent_model_threshold_placebos.pdf \
	../output/parent_model_bootstrap_draws.parquet \
	../output/parent_model_bootstrap_summary.csv \
	../output/parent_model_bootstrap_refit_status.csv \
	../output/parent_model_bootstrap_qc.csv \
	../output/parent_model_bootstrap_intervals.pdf

../output/parent_model_pseudo_policy_years.csv: audit_parent_model_placebos.R \
	parent_model_audit_functions.R \
	../../../_lib/source_pipeline_utils.R \
	../../../_lib/parent_no_notch_model.R \
	../input/historical_enhanced_parent_model_panel.parquet \
	../input/post_policy_enhanced_parent_model_panel.parquet | ../output
	$(R) $< $(TRAINING_START_YEAR) $(TRAINING_END_YEAR) \
		$(PSEUDO_START_YEAR) $(PSEUDO_END_YEAR) $(TRAINING_ENDPOINTS) \
		$(MIN_UNITS) $(MIN_CATEGORY_ROWS) $(THRESHOLD_MIN) $(THRESHOLD_MAX) \
		$(COUNTERFACTUAL_MAX_UNITS) $(POST_YEAR)

../output/parent_model_threshold_placebos.csv \
../output/parent_model_leave_one_year_out.csv \
../output/parent_model_training_endpoints.csv \
../output/parent_model_threshold_placebos.pdf: ../output/parent_model_pseudo_policy_years.csv
	@test -s "$@"

../output/parent_model_bootstrap_draws.parquet: bootstrap_parent_model.R \
	parent_model_audit_functions.R \
	../../../_lib/source_pipeline_utils.R \
	../../../_lib/parent_no_notch_model.R \
	../input/historical_enhanced_parent_model_panel.parquet \
	../input/post_policy_enhanced_parent_model_panel.parquet | ../output
	$(R) $< $(TRAINING_START_YEAR) $(TRAINING_END_YEAR) $(POST_YEAR) \
		$(MIN_UNITS) $(MIN_CATEGORY_ROWS) $(THRESHOLD_UNITS) \
		$(COUNTERFACTUAL_MAX_UNITS) $(BOOTSTRAP_REPS) $(BOOTSTRAP_SEED) \
		$(INTERVAL_LOWER) $(INTERVAL_UPPER)

../output/parent_model_bootstrap_summary.csv \
../output/parent_model_bootstrap_refit_status.csv \
../output/parent_model_bootstrap_qc.csv: ../output/parent_model_bootstrap_draws.parquet
	@test -s "$@"

../output/parent_model_bootstrap_intervals.pdf: plot_parent_model_bootstrap.R \
	../output/parent_model_bootstrap_summary.csv | ../output
	$(R) $<

../input/historical_enhanced_parent_model_panel.parquet: ../../../build_parent_model_panel/output/historical_enhanced_parent_model_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_enhanced_parent_model_panel.parquet: ../../../build_parent_model_panel/output/post_policy_enhanced_parent_model_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/historical_enhanced_parent_model_panel.parquet \
	../input/post_policy_enhanced_parent_model_panel.parquet

include ../../generic.make
