SHELL := bash
include ../../shell_functions.make

MIN_UNITS := 6
MIN_CATEGORY_ROWS := 30
COUNTERFACTUAL_MAX_UNITS := 400
PLOT_MIN_UNITS := 50
PLOT_MAX_UNITS := 220

all: ../output/enhanced_parent_2025_counterfactual.csv \
	../output/enhanced_parent_model_parameters.csv \
	../output/enhanced_parent_2025_scores.parquet \
	../output/enhanced_parent_2025_distribution.csv \
	../output/enhanced_parent_2025_counterfactual.pdf \
	../output/enhanced_parent_dob_i1_complete_case_2025_counterfactual.csv \
	../output/enhanced_parent_dob_i1_complete_case_model_parameters.csv \
	../output/enhanced_parent_dob_i1_complete_case_2025_scores.parquet \
	../output/enhanced_parent_dob_i1_complete_case_2025_distribution.csv \
	../output/enhanced_parent_dob_i1_complete_case_2025_counterfactual.pdf

../output/enhanced_parent_2025_counterfactual.csv: estimate_parent_no_notch_model.R \
	../../_lib/source_pipeline_utils.R \
	../../_lib/parent_no_notch_model.R \
	../input/historical_enhanced_parent_model_panel.parquet \
	../input/post_policy_enhanced_parent_model_panel.parquet | ../output
	$(R) $< hdb_priority $(MIN_UNITS) $(MIN_CATEGORY_ROWS) $(COUNTERFACTUAL_MAX_UNITS) $(PLOT_MIN_UNITS) $(PLOT_MAX_UNITS)

../output/enhanced_parent_model_parameters.csv \
../output/enhanced_parent_2025_scores.parquet \
../output/enhanced_parent_2025_distribution.csv \
../output/enhanced_parent_2025_counterfactual.pdf: ../output/enhanced_parent_2025_counterfactual.csv
	@test -s "$@"

../output/enhanced_parent_dob_i1_complete_case_2025_counterfactual.csv: estimate_parent_no_notch_model.R \
	../../_lib/source_pipeline_utils.R \
	../../_lib/parent_no_notch_model.R \
	../input/historical_enhanced_parent_model_panel.parquet \
	../input/post_policy_enhanced_parent_model_panel.parquet | ../output
	$(R) $< dob_i1_complete_case $(MIN_UNITS) $(MIN_CATEGORY_ROWS) $(COUNTERFACTUAL_MAX_UNITS) $(PLOT_MIN_UNITS) $(PLOT_MAX_UNITS)

../output/enhanced_parent_dob_i1_complete_case_model_parameters.csv \
../output/enhanced_parent_dob_i1_complete_case_2025_scores.parquet \
../output/enhanced_parent_dob_i1_complete_case_2025_distribution.csv \
../output/enhanced_parent_dob_i1_complete_case_2025_counterfactual.pdf: ../output/enhanced_parent_dob_i1_complete_case_2025_counterfactual.csv
	@test -s "$@"

../input/historical_enhanced_parent_model_panel.parquet: ../../build_parent_model_panel/output/historical_enhanced_parent_model_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_enhanced_parent_model_panel.parquet: ../../build_parent_model_panel/output/post_policy_enhanced_parent_model_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/historical_enhanced_parent_model_panel.parquet \
	../input/post_policy_enhanced_parent_model_panel.parquet

include ../../generic.make
