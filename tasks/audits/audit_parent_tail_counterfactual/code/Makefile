include ../../../shared/code/shell_functions.make

HISTORICAL_START_YEAR := 2017
HISTORICAL_START_YEARS := 2011,2014,2017,2019
HISTORICAL_END_YEAR := 2022
POST_YEAR := 2025
MIN_UNITS := 6
TAIL_CUTOFF := 99
MINIMUM_FOLLOWUP_DAYS := 180

all: ../output/analysis_samples_summary.csv \
	../output/analysis_sample_flow.csv \
	../output/analysis_sample_qc.csv \
	../output/balance_variable_summary_unweighted_c99.csv \
	../output/category_support_c99.csv \
	../output/tail_pre_c99.rds \
	../output/tail_post_c99.rds \
	../output/tail_pre_c99_calibration_weights.csv \
	../output/calibration_standardization_c99.csv \
	../output/calibration_balance_c99.csv \
	../output/calibration_weight_diagnostics_c99.csv \
	../output/calibration_cohort_composition_c99.csv \
	../output/counterfactual_exact_counts_c99.csv \
	../output/counterfactual_summary_c99.csv \
	../output/counterfactual_cumulative_diagnostics_c99.csv \
	../output/counterfactual_structural_frontier_c99.csv \
	../output/counterfactual_exact_counts_c99.png \
	../output/counterfactual_cumulative_diagnostics_c99.png \
	../output/historical_window_comparison_c99.csv \
	../output/historical_window_cohort_composition_c99.csv \
	../output/historical_window_parent_weights_c99.csv

../output/analysis_samples_summary.csv: construct_parent_tail_samples.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/historical_parent_site_characteristics.parquet \
	../input/post_policy_parent_site_characteristics.parquet ../input/symmetric_parent_membership.parquet \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | \
	../output
	$(R) $< $(HISTORICAL_START_YEAR) $(HISTORICAL_END_YEAR) $(POST_YEAR) \
		$(MIN_UNITS) $(TAIL_CUTOFF) $(MINIMUM_FOLLOWUP_DAYS)

../output/analysis_sample_flow.csv \
../output/analysis_sample_qc.csv \
../output/balance_variable_summary_unweighted_c99.csv \
../output/category_support_c99.csv \
../output/tail_pre_c99.rds \
../output/tail_post_c99.rds: ../output/analysis_samples_summary.csv
	$(RECOVER) -W construct_parent_tail_samples.R all

../output/tail_pre_c99_calibration_weights.csv: calibrate_parent_tail_weights.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../output/tail_pre_c99.rds ../output/tail_post_c99.rds \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | \
	../output
	$(R) $<

../output/calibration_standardization_c99.csv \
../output/calibration_balance_c99.csv \
../output/calibration_weight_diagnostics_c99.csv \
../output/calibration_cohort_composition_c99.csv: ../output/tail_pre_c99_calibration_weights.csv
	$(RECOVER) -W calibrate_parent_tail_weights.R all

../output/counterfactual_exact_counts_c99.csv: construct_weighted_counterfactual.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../output/tail_pre_c99.rds ../output/tail_post_c99.rds \
	../output/tail_pre_c99_calibration_weights.csv \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/counterfactual_summary_c99.csv \
../output/counterfactual_cumulative_diagnostics_c99.csv \
../output/counterfactual_structural_frontier_c99.csv \
../output/counterfactual_exact_counts_c99.png \
../output/counterfactual_cumulative_diagnostics_c99.png: ../output/counterfactual_exact_counts_c99.csv
	$(RECOVER) -W construct_weighted_counterfactual.R all

../output/historical_window_comparison_c99.csv: compare_historical_windows.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/historical_parent_site_characteristics.parquet \
	../input/post_policy_parent_site_characteristics.parquet ../input/symmetric_parent_membership.parquet \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | \
	../output
	$(R) $< $(HISTORICAL_START_YEARS) $(HISTORICAL_END_YEAR) \
		$(POST_YEAR) $(TAIL_CUTOFF) $(MINIMUM_FOLLOWUP_DAYS)

../output/historical_window_cohort_composition_c99.csv \
../output/historical_window_parent_weights_c99.csv: ../output/historical_window_comparison_c99.csv
	$(RECOVER) -W compare_historical_windows.R all

../input/historical_parent_site_characteristics.parquet: ../../../build_parent_site_characteristics/output/historical_parent_site_characteristics.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_parent_site_characteristics.parquet: ../../../build_parent_site_characteristics/output/post_policy_parent_site_characteristics.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/historical_parent_site_characteristics.parquet \
	../input/post_policy_parent_site_characteristics.parquet \
	../input/symmetric_parent_membership.parquet

../../../build_parent_site_characteristics/output/historical_parent_site_characteristics.parquet \
	../../../build_parent_site_characteristics/output/post_policy_parent_site_characteristics.parquet: check-build_parent_site_characteristics ;

.PHONY: check-build_parent_site_characteristics

check-build_parent_site_characteristics:
	$(MAKE) -C ../../../build_parent_site_characteristics/code all ../output/historical_parent_site_characteristics.parquet ../output/post_policy_parent_site_characteristics.parquet

../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet: check-construct_parent_cohorts ;

.PHONY: check-construct_parent_cohorts

check-construct_parent_cohorts:
	$(MAKE) -C ../../../construct_parent_cohorts/code all ../output/symmetric_parent_membership.parquet

include ../../../shared/code/generic.make
