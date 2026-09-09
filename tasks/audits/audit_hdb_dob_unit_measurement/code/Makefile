include ../../../shared/code/shell_functions.make

POST_YEAR := 2025
MIN_UNITS := 6

all: ../output/hdb_dob_unit_disagreement_filings.csv ../output/hdb_dob_unit_comparison.csv \
	../output/hdb_dob_unit_disagreements.csv \
	\
	../output/hdb_dob_exact_99_disagreements.csv \
	../output/hdb_dob_unit_measurement_summary.csv

../output/hdb_dob_unit_disagreement_filings.csv: audit_hdb_dob_unit_measurement.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/hdb_mappluto_site_panel.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet ../input/dob_now_new_building_filings.parquet \
	../input/post_policy_filing_link_fields.parquet \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< $(POST_YEAR) $(MIN_UNITS)

../output/hdb_dob_unit_comparison.csv \
	../output/hdb_dob_unit_disagreements.csv \
	../output/hdb_dob_exact_99_disagreements.csv \
	../output/hdb_dob_unit_measurement_summary.csv: ../output/hdb_dob_unit_disagreement_filings.csv
	$(MAKE) -W audit_hdb_dob_unit_measurement.R all

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

../../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet: check-build_hdb_mappluto_site_panel ;

.PHONY: check-build_hdb_mappluto_site_panel

check-build_hdb_mappluto_site_panel:
	$(MAKE) -C ../../../build_hdb_mappluto_site_panel/code all ../output/hdb_mappluto_site_panel.parquet

../../../load_dcp_housing_database_raw/output/dcp_housing_database_project_level_raw_25q4.parquet: check-load_dcp_housing_database_raw ;

.PHONY: check-load_dcp_housing_database_raw

check-load_dcp_housing_database_raw:
	$(MAKE) -C ../../../load_dcp_housing_database_raw/code all ../output/dcp_housing_database_project_level_raw_25q4.parquet

../../../stage_dob_now_new_building_filings/output/dob_now_new_building_filings.parquet: check-stage_dob_now_new_building_filings ;

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_filings.parquet

../../../construct_post_policy_parent_crosswalk/output/post_policy_filing_link_fields.parquet: check-construct_post_policy_parent_crosswalk ;

.PHONY: check-construct_post_policy_parent_crosswalk

check-construct_post_policy_parent_crosswalk:
	$(MAKE) -C ../../../construct_post_policy_parent_crosswalk/code all ../output/post_policy_filing_link_fields.parquet

include ../../../shared/code/generic.make
