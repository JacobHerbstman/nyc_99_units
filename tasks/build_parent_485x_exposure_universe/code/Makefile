SHELL := bash
include ../../shell_functions.make

PRE_START_YEAR := 2011
PRE_END_YEAR := 2022
POST_START_DATE := 2023-01-01
MIN_UNITS := 6

all: ../output/parent_485x_exposure_universe.csv

../output/parent_485x_exposure_universe.csv: build_parent_485x_exposure_universe.R \
	Makefile \
	../../_lib/source_pipeline_utils.R \
	../input/symmetric_parent_membership.parquet \
	../input/dcp_housing_database_project_level_25q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/historical_parent_filing_link_fields.parquet | ../output
	$(R) $< $(PRE_START_YEAR) $(PRE_END_YEAR) $(POST_START_DATE) \
		$(MIN_UNITS)

../input/symmetric_parent_membership.parquet: ../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_housing_database_project_level_25q4.parquet: ../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_filing_link_fields.parquet: ../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/symmetric_parent_membership.parquet \
	../input/dcp_housing_database_project_level_25q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/historical_parent_filing_link_fields.parquet

include ../../generic.make
