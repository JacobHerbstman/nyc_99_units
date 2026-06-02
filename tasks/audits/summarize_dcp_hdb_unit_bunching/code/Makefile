SHELL := bash

all: ../output/dcp_hdb_unit_bunching_year_summary.csv \
	../output/dcp_hdb_unit_bunching_period_summary.csv \
	../output/dcp_hdb_unit_bunching_exact_counts.csv \
	../output/dcp_hdb_unit_bunching_sample_qc.csv \
	../output/dcp_hdb_unit_bunching_pre_post_exact.pdf \
	../output/dcp_hdb_unit_bunching_pre_post_exact.png \
	../output/dcp_hdb_unit_bunching_bin_sensitivity.pdf \
	../output/dcp_hdb_unit_bunching_bin_sensitivity.png \
	../output/dcp_hdb_unit_bunching_year_start.pdf \
	../output/dcp_hdb_unit_bunching_year_start.png

../output/dcp_hdb_unit_bunching_year_summary.csv: summarize_dcp_hdb_unit_bunching.R ../../../_lib/source_pipeline_utils.R ../input/dcp_housing_database_project_level_25q4.parquet | ../output
	$(R) $<

../output/dcp_hdb_unit_bunching_period_summary.csv ../output/dcp_hdb_unit_bunching_exact_counts.csv ../output/dcp_hdb_unit_bunching_sample_qc.csv ../output/dcp_hdb_unit_bunching_pre_post_exact.pdf ../output/dcp_hdb_unit_bunching_pre_post_exact.png ../output/dcp_hdb_unit_bunching_bin_sensitivity.pdf ../output/dcp_hdb_unit_bunching_bin_sensitivity.png ../output/dcp_hdb_unit_bunching_year_start.pdf ../output/dcp_hdb_unit_bunching_year_start.png: ../output/dcp_hdb_unit_bunching_year_summary.csv
	@test -s "$@"

../input/dcp_housing_database_project_level_25q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dcp_housing_database_project_level_25q4.parquet

include ../../generic.make
