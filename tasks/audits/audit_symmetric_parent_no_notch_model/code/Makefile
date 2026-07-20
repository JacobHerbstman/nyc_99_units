SHELL := bash
include ../../../shell_functions.make

MIN_UNITS := 6
MIN_CATEGORY_ROWS := 30
COUNTERFACTUAL_MAX_UNITS := 400
PLOT_MIN_UNITS := 50
PLOT_MAX_UNITS := 220

all: ../output/symmetric_parent_model_counterfactuals.csv \
	../output/symmetric_parent_model_comparison.csv \
	../output/symmetric_parent_model_parameters.csv \
	../output/symmetric_parent_model_scores.parquet \
	../output/symmetric_parent_model_distributions.csv \
	../output/symmetric_parent_model_counterfactuals.pdf

../output/symmetric_parent_model_counterfactuals.csv: estimate_symmetric_parent_no_notch_model.R \
	../../../_lib/source_pipeline_utils.R \
	../../../_lib/parent_no_notch_model.R \
	../input/historical_enhanced_parent_model_panel.parquet \
	../input/post_policy_enhanced_parent_model_panel.parquet \
	../input/enhanced_parent_2025_counterfactual.csv | ../output
	$(R) $< $(MIN_UNITS) $(MIN_CATEGORY_ROWS) \
		$(COUNTERFACTUAL_MAX_UNITS) $(PLOT_MIN_UNITS) $(PLOT_MAX_UNITS)

../output/symmetric_parent_model_comparison.csv \
../output/symmetric_parent_model_parameters.csv \
../output/symmetric_parent_model_scores.parquet \
../output/symmetric_parent_model_distributions.csv \
../output/symmetric_parent_model_counterfactuals.pdf: ../output/symmetric_parent_model_counterfactuals.csv
	@test -s "$@"

../input/historical_enhanced_parent_model_panel.parquet: ../../../build_parent_model_panel/output/historical_enhanced_parent_model_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_enhanced_parent_model_panel.parquet: ../../../build_parent_model_panel/output/post_policy_enhanced_parent_model_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/enhanced_parent_2025_counterfactual.csv: ../../../estimate_parent_no_notch_model/output/enhanced_parent_2025_counterfactual.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/historical_enhanced_parent_model_panel.parquet \
	../input/post_policy_enhanced_parent_model_panel.parquet \
	../input/enhanced_parent_2025_counterfactual.csv

include ../../generic.make
