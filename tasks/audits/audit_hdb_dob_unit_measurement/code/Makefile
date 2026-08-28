SHELL := bash
include ../../../shell_functions.make

POST_YEAR := 2025
MIN_UNITS := 6

all: ../output/hdb_dob_unit_comparison.csv \
	../output/hdb_dob_unit_disagreements.csv \
	../output/hdb_dob_unit_disagreement_filings.csv \
	../output/hdb_dob_exact_99_disagreements.csv \
	../output/hdb_dob_unit_measurement_summary.csv

../output/hdb_dob_unit_comparison.csv: audit_hdb_dob_unit_measurement.R \
	../../../_lib/source_pipeline_utils.R \
	../input/hdb_mappluto_site_panel.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../input/dob_now_new_building_filings.parquet \
	../input/post_policy_filing_link_fields.parquet | ../output
	$(R) $< $(POST_YEAR) $(MIN_UNITS)

../output/hdb_dob_unit_disagreements.csv \
../output/hdb_dob_unit_disagreement_filings.csv \
../output/hdb_dob_exact_99_disagreements.csv \
../output/hdb_dob_unit_measurement_summary.csv: ../output/hdb_dob_unit_comparison.csv
	@test -s "$@"

../input/hdb_mappluto_site_panel.parquet: ../../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_housing_database_project_level_raw_25q4.parquet: ../../../load_dcp_housing_database_raw/output/dcp_housing_database_project_level_raw_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_filing_link_fields.parquet: ../../../construct_post_policy_parent_crosswalk/output/post_policy_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_site_panel.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../input/dob_now_new_building_filings.parquet \
	../input/post_policy_filing_link_fields.parquet

include ../../generic.make
