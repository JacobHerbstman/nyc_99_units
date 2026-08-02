SHELL := bash
include ../../../shell_functions.make

TRAINING_START_YEAR := 2019
TRAINING_END_YEAR := 2022
POST_YEAR := 2025
MIN_UNITS := 6
MIN_CATEGORY_ROWS := 30
THRESHOLD_UNITS := 100
UNIT_BIN_UPPER_BOUNDS := 29,49,79,98,99,119,149,199
LOCAL_LOWER_UNITS := 50
LOCAL_UPPER_UNITS := 150
SUPPORT_LOWER := 0.01
SUPPORT_UPPER := 0.99
MATURITY_DAYS := 180

all: ../output/parent_threshold_mass_balance.csv \
	../output/parent_mass_balance_by_unit_bin.csv \
	../output/annual_parent_counts_by_unit_bin.csv \
	../output/annual_parent_local_mass.csv \
	../output/parent_structure_mass_balance.csv \
	../output/preferred_exact_99_broad_link_sensitivity.csv \
	../output/parent_composition_comparison.csv \
	../output/parent_covariate_support.csv \
	../output/parent_prediction_support_scores.parquet \
	../output/parent_placebo_conservation_gaps.csv \
	../output/parent_mass_balance_audit.pdf \
	../output/parent_mass_balance_qc.csv

../output/parent_threshold_mass_balance.csv: audit_parent_mass_balance.R \
	../../../_lib/source_pipeline_utils.R \
	../../../_lib/parent_no_notch_model.R \
	../input/historical_enhanced_parent_model_panel.parquet \
	../input/post_policy_enhanced_parent_model_panel.parquet \
	../input/enhanced_parent_2025_scores.parquet \
	../input/enhanced_parent_2025_distribution.csv \
	../input/enhanced_parent_2025_counterfactual.csv \
	../input/symmetric_parent_membership.parquet \
	../input/provisional_parent_universal_membership.parquet \
	../input/parent_model_pseudo_policy_years.csv | ../output
	$(R) $< $(TRAINING_START_YEAR) $(TRAINING_END_YEAR) $(POST_YEAR) \
		$(MIN_UNITS) $(MIN_CATEGORY_ROWS) $(THRESHOLD_UNITS) \
		$(UNIT_BIN_UPPER_BOUNDS) $(LOCAL_LOWER_UNITS) \
		$(LOCAL_UPPER_UNITS) $(SUPPORT_LOWER) $(SUPPORT_UPPER) \
		$(MATURITY_DAYS)

../output/parent_mass_balance_by_unit_bin.csv \
../output/annual_parent_counts_by_unit_bin.csv \
../output/annual_parent_local_mass.csv \
../output/parent_structure_mass_balance.csv \
../output/preferred_exact_99_broad_link_sensitivity.csv \
../output/parent_composition_comparison.csv \
../output/parent_covariate_support.csv \
../output/parent_prediction_support_scores.parquet \
../output/parent_placebo_conservation_gaps.csv \
../output/parent_mass_balance_qc.csv: ../output/parent_threshold_mass_balance.csv
	@test -s "$@"

../output/parent_mass_balance_audit.pdf: plot_parent_mass_balance.R \
	../output/parent_mass_balance_by_unit_bin.csv \
	../output/annual_parent_local_mass.csv \
	../output/preferred_exact_99_broad_link_sensitivity.csv \
	../output/parent_composition_comparison.csv \
	../output/parent_covariate_support.csv \
	../output/parent_prediction_support_scores.parquet \
	../output/parent_placebo_conservation_gaps.csv | ../output
	$(R) $< $(TRAINING_START_YEAR) $(TRAINING_END_YEAR) $(POST_YEAR) \
		$(THRESHOLD_UNITS) $(LOCAL_LOWER_UNITS) $(LOCAL_UPPER_UNITS)

../input/historical_enhanced_parent_model_panel.parquet: ../../../build_parent_model_panel/output/historical_enhanced_parent_model_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_enhanced_parent_model_panel.parquet: ../../../build_parent_model_panel/output/post_policy_enhanced_parent_model_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/enhanced_parent_2025_scores.parquet: ../../../estimate_parent_no_notch_model/output/enhanced_parent_2025_scores.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/enhanced_parent_2025_distribution.csv: ../../../estimate_parent_no_notch_model/output/enhanced_parent_2025_distribution.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/enhanced_parent_2025_counterfactual.csv: ../../../estimate_parent_no_notch_model/output/enhanced_parent_2025_counterfactual.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/provisional_parent_universal_membership.parquet: ../../audit_provisional_parent_no_notch/output/provisional_parent_universal_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_model_pseudo_policy_years.csv: ../../audit_parent_model_inference_placebos/output/parent_model_pseudo_policy_years.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/historical_enhanced_parent_model_panel.parquet \
	../input/post_policy_enhanced_parent_model_panel.parquet \
	../input/enhanced_parent_2025_scores.parquet \
	../input/enhanced_parent_2025_distribution.csv \
	../input/enhanced_parent_2025_counterfactual.csv \
	../input/symmetric_parent_membership.parquet \
	../input/provisional_parent_universal_membership.parquet \
	../input/parent_model_pseudo_policy_years.csv

include ../../generic.make
