include ../../../shared/code/shell_functions.make

START_YEAR := 2010
END_YEAR := 2023
MIN_UNITS := 6
NEARBY_METERS := 100
REVIEW_METERS := 250
MAX_FILING_DAYS := 365

all: ../output/historical_parent_filing_link_fields.parquet \
	../output/historical_parent_candidate_pairs.parquet \
	../output/historical_parent_filing_coverage_by_year.csv \
	../output/historical_parent_link_signal_summary.csv \
	../output/historical_parent_grouping_sensitivity.csv \
	../output/historical_parent_source_inventory.csv \
	../output/historical_parent_feasibility_summary.csv \
	../output/historical_parent_link_feasibility_qc.csv

../output/historical_parent_candidate_pairs.parquet: audit_historical_parent_link_feasibility.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../output/historical_parent_filing_link_fields.parquet \
	../output/historical_parent_source_inventory.csv ../output/historical_parent_filing_coverage_by_year.csv \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | \
	../output
	$(R) $< $(NEARBY_METERS) $(REVIEW_METERS) $(MAX_FILING_DAYS)

../output/historical_parent_filing_link_fields.parquet: extract_historical_parent_link_fields.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/hdb_mappluto_site_panel.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet ../input/mappluto_files.csv \
	../input/mappluto_release_calendar.csv \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< $(START_YEAR) $(END_YEAR) $(MIN_UNITS)

../output/historical_parent_source_inventory.csv ../output/historical_parent_filing_coverage_by_year.csv: ../output/historical_parent_filing_link_fields.parquet
	$(RECOVER) -W extract_historical_parent_link_fields.R all

../output/historical_parent_link_signal_summary.csv ../output/historical_parent_grouping_sensitivity.csv ../output/historical_parent_feasibility_summary.csv ../output/historical_parent_link_feasibility_qc.csv: ../output/historical_parent_candidate_pairs.parquet
	$(RECOVER) -W audit_historical_parent_link_feasibility.R all

../input/hdb_mappluto_site_panel.parquet: ../../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_housing_database_project_level_raw_25q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_files.csv: ../../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_release_calendar.csv: ../../../build_hdb_mappluto_site_panel/output/mappluto_release_calendar.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_site_panel.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/mappluto_files.csv \
	../input/mappluto_release_calendar.csv

../../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet: check-build_hdb_mappluto_site_panel ;

.PHONY: check-build_hdb_mappluto_site_panel

check-build_hdb_mappluto_site_panel:
	$(MAKE) -C ../../../build_hdb_mappluto_site_panel/code all ../output/hdb_mappluto_site_panel.parquet

../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_25q4.parquet: check-stage_dcp_housing_database ;

.PHONY: check-stage_dcp_housing_database

check-stage_dcp_housing_database:
	$(MAKE) -C ../../../stage_dcp_housing_database/code all ../output/dcp_housing_database_project_level_raw_25q4.parquet

../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet: check-stage_dob_now_new_building_filings ;

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet

../../../fetch_mappluto_archive/output/mappluto_files.csv: check-fetch_mappluto_archive ;

.PHONY: check-fetch_mappluto_archive

check-fetch_mappluto_archive:
	$(MAKE) -C ../../../fetch_mappluto_archive/code all ../output/mappluto_files.csv

../../../build_hdb_mappluto_site_panel/output/mappluto_release_calendar.csv: check-build_hdb_mappluto_site_panel ;

.PHONY: check-build_hdb_mappluto_site_panel

include ../../../shared/code/generic.make
