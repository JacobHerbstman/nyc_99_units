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
	../output/symmetric_parent_model_counterfactuals.pdf \
	../output/historical_symmetric_parent_model_panel.parquet \
	../output/post_policy_symmetric_parent_model_panel.parquet \
	../output/symmetric_parent_model_panel_qc.csv \
	../output/unmatched_post_feature_rows.csv

../output/symmetric_parent_model_counterfactuals.csv: estimate_symmetric_parent_no_notch_model.R \
	../../../_lib/source_pipeline_utils.R \
	../../../_lib/parent_no_notch_model.R \
	../output/historical_symmetric_parent_model_panel.parquet \
	../output/post_policy_symmetric_parent_model_panel.parquet \
	../input/enhanced_parent_2025_counterfactual.csv | ../output
	$(R) $< $(MIN_UNITS) $(MIN_CATEGORY_ROWS) \
		$(COUNTERFACTUAL_MAX_UNITS) $(PLOT_MIN_UNITS) $(PLOT_MAX_UNITS)

../output/symmetric_parent_model_comparison.csv \
../output/symmetric_parent_model_parameters.csv \
../output/symmetric_parent_model_scores.parquet \
../output/symmetric_parent_model_distributions.csv \
../output/symmetric_parent_model_counterfactuals.pdf: ../output/symmetric_parent_model_counterfactuals.csv
	@test -s "$@"

../output/historical_symmetric_parent_model_panel.parquet: build_symmetric_parent_model_panels.R \
	../../../_lib/source_pipeline_utils.R \
	../input/symmetric_parent_membership.parquet \
	../input/hdb_mappluto_training_panel.parquet \
	../input/dcp_mappluto_archive_23v3_1.parquet | ../output
	$(R) $<

../output/post_policy_symmetric_parent_model_panel.parquet \
../output/symmetric_parent_model_panel_qc.csv \
../output/unmatched_post_feature_rows.csv: ../output/historical_symmetric_parent_model_panel.parquet
	@test -s "$@"

../input/symmetric_parent_membership.parquet: ../../audit_symmetric_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v3_1.parquet: ../../../stage_mappluto_lots/output/dcp_mappluto_archive_23v3_1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/enhanced_parent_2025_counterfactual.csv: ../../../estimate_parent_no_notch_model/output/enhanced_parent_2025_counterfactual.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/symmetric_parent_membership.parquet \
	../input/hdb_mappluto_training_panel.parquet \
	../input/dcp_mappluto_archive_23v3_1.parquet \
	../input/enhanced_parent_2025_counterfactual.csv

include ../../generic.make
