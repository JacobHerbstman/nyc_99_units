SHELL := bash
include ../../shell_functions.make

START_YEAR := 2010
END_YEAR := 2023
MIN_UNITS := 6
NEARBY_METERS := 100
REVIEW_METERS := 250
MAX_FILING_DAYS := 365

all: ../output/historical_parent_filing_link_fields.parquet \
	../output/historical_parent_candidate_pairs.parquet

../output/historical_parent_candidate_pairs.parquet: construct_historical_parent_candidate_pairs.R \
	Makefile \
	../../_lib/source_pipeline_utils.R \
	../output/historical_parent_filing_link_fields.parquet | ../output
	$(R) $< $(NEARBY_METERS) $(REVIEW_METERS) $(MAX_FILING_DAYS)

../output/historical_parent_filing_link_fields.parquet: extract_historical_parent_link_fields.R \
	Makefile \
	../../_lib/source_pipeline_utils.R \
	../input/hdb_mappluto_training_panel.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/mappluto_files.csv | ../output
	$(R) $< $(START_YEAR) $(END_YEAR) $(MIN_UNITS)

../input/hdb_mappluto_training_panel.parquet: ../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_housing_database_project_level_raw_25q4.parquet: ../../load_dcp_housing_database_raw/output/dcp_housing_database_project_level_raw_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/mappluto_files.csv

include ../../generic.make
