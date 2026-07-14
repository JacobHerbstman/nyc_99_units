SHELL := bash
include ../../../shell_functions.make

PRE_START_YEAR := 2010
PRE_END_YEAR := 2023
POST_YEAR := 2025
MIN_UNITS := 6
MAX_FILING_DAYS := 365
CORROBORATION_DAYS := 30
MIN_CATEGORY_ROWS := 30
COUNTERFACTUAL_MAX_UNITS := 400

all: ../output/historical_parent_model_panel.parquet \
	../output/post_policy_parent_model_panel.parquet \
	../output/parent_model_membership.parquet \
	../output/post_policy_parent_link_pairs.csv \
	../output/parent_panel_construction_qc.csv \
	../output/parent_model_validation_metrics.csv \
	../output/parent_model_validation_summary.csv \
	../output/parent_model_final_parameters.csv \
	../output/parent_model_2025_scores.parquet \
	../output/parent_model_2025_counterfactual.csv \
	../output/parent_model_2025_distribution.csv \
	../output/parent_model_comparison.pdf \
	../output/parent_model_comparison.png

../output/historical_parent_model_panel.parquet: build_parent_model_panels.R \
	../../../_lib/source_pipeline_utils.R \
	../input/hdb_mappluto_training_panel.parquet \
	../input/historical_parent_candidate_pairs.parquet \
	../input/historical_polygon_adjacency_pairs.parquet \
	../input/developer_opportunity_job_crosswalk.parquet \
	../input/mappluto_files.csv | ../output
	$(R) $< $(PRE_START_YEAR) $(PRE_END_YEAR) $(POST_YEAR) $(MIN_UNITS) $(MAX_FILING_DAYS) $(CORROBORATION_DAYS)

../output/post_policy_parent_model_panel.parquet \
	../output/parent_model_membership.parquet \
	../output/post_policy_parent_link_pairs.csv \
	../output/parent_panel_construction_qc.csv: ../output/historical_parent_model_panel.parquet
	@test -s "$@"

../output/parent_model_validation_metrics.csv: compare_parent_no_notch_models.R \
	../../../_lib/source_pipeline_utils.R \
	../output/historical_parent_model_panel.parquet \
	../output/post_policy_parent_model_panel.parquet \
	../output/parent_model_membership.parquet | ../output
	$(R) $< $(MIN_UNITS) $(MIN_CATEGORY_ROWS) $(COUNTERFACTUAL_MAX_UNITS)

../output/parent_model_validation_summary.csv \
	../output/parent_model_final_parameters.csv \
	../output/parent_model_2025_scores.parquet \
	../output/parent_model_2025_counterfactual.csv \
	../output/parent_model_2025_distribution.csv \
	../output/parent_model_comparison.pdf \
	../output/parent_model_comparison.png: ../output/parent_model_validation_metrics.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_candidate_pairs.parquet: ../../audit_historical_parent_link_feasibility/output/historical_parent_candidate_pairs.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_polygon_adjacency_pairs.parquet: ../../audit_historical_exact_parcel_adjacency/output/historical_polygon_adjacency_pairs.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/developer_opportunity_job_crosswalk.parquet: ../../audit_developer_opportunity_crosswalk/output/developer_opportunity_job_crosswalk.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_files.csv: ../../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet \
	../input/historical_parent_candidate_pairs.parquet \
	../input/historical_polygon_adjacency_pairs.parquet \
	../input/developer_opportunity_job_crosswalk.parquet \
	../input/mappluto_files.csv

include ../../generic.make
