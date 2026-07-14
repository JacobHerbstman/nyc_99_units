SHELL := bash
include ../../../shell_functions.make

all: ../output/no_notch_residual_source_decomposition.csv \
	../output/no_notch_residual_reuse_summary.csv \
	../output/no_notch_residual_group_summary.csv \
	../output/no_notch_residual_continuous_correlations.csv \
	../output/no_notch_residual_site_year_summary.csv \
	../output/no_notch_residual_tail_cases.csv \
	../output/no_notch_residual_dob_coverage.csv \
	../output/no_notch_residual_dob_diagnostics.csv \
	../output/no_notch_residual_applicant_summary.csv \
	../output/no_notch_residual_project_predictions.parquet \
	../output/no_notch_residual_diagnostics.pdf \
	../output/no_notch_residual_diagnostics.png

../output/no_notch_residual_source_decomposition.csv: audit_no_notch_residual_patterns.R ../input/hdb_mappluto_training_panel.parquet ../input/no_notch_heldout_predictions.parquet ../input/no_notch_time_windows.csv ../input/dob_now_new_building_initial_filings.parquet | ../output
	$(R) $<

../output/no_notch_residual_reuse_summary.csv ../output/no_notch_residual_group_summary.csv ../output/no_notch_residual_continuous_correlations.csv ../output/no_notch_residual_site_year_summary.csv ../output/no_notch_residual_tail_cases.csv ../output/no_notch_residual_dob_coverage.csv ../output/no_notch_residual_dob_diagnostics.csv ../output/no_notch_residual_applicant_summary.csv ../output/no_notch_residual_project_predictions.parquet ../output/no_notch_residual_diagnostics.pdf ../output/no_notch_residual_diagnostics.png: ../output/no_notch_residual_source_decomposition.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/no_notch_heldout_predictions.parquet: ../../audit_no_notch_unit_distribution/output/no_notch_heldout_predictions.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/no_notch_time_windows.csv: ../../audit_no_notch_unit_distribution/output/no_notch_time_windows.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet \
	../input/no_notch_heldout_predictions.parquet \
	../input/no_notch_time_windows.csv \
	../input/dob_now_new_building_initial_filings.parquet

include ../../generic.make
