include ../../shared/code/shell_functions.make

PRE_START_YEAR := 2011
PRE_END_YEAR := 2022
POST_START_DATE := 2023-01-01
MIN_UNITS := 6

ifneq ($(filter command,$(origin PRE_START_YEAR) $(origin PRE_END_YEAR) $(origin POST_START_DATE) $(origin MIN_UNITS)),)
$(error These fixed-name outputs use the settings recorded in this Makefile; edit those settings here so Make tracks the change)
endif

all: ../output/parent_485x_exposure_universe.csv \
	../report/parent_485x_exposure_universe.txt

../output/parent_485x_exposure_universe.csv: build_parent_485x_exposure_universe.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/symmetric_parent_membership.parquet \
	../input/dcp_housing_database_project_level_25q4.parquet ../input/dob_now_new_building_initial_filings.parquet \
	../input/historical_parent_filing_link_fields.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $< $(PRE_START_YEAR) $(PRE_END_YEAR) $(POST_START_DATE) \
		$(MIN_UNITS)


../report/parent_485x_exposure_universe.txt: report_data.R ../../shared/code/write_data_report.R ../output/parent_485x_exposure_universe.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_485x_exposure_universe


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

../../construct_parent_cohorts/output/symmetric_parent_membership.parquet: check-construct_parent_cohorts ;

.PHONY: check-construct_parent_cohorts

check-construct_parent_cohorts:
	$(MAKE) -C ../../construct_parent_cohorts/code all ../output/symmetric_parent_membership.parquet

../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet: check-stage_dcp_housing_database ;

.PHONY: check-stage_dcp_housing_database

check-stage_dcp_housing_database:
	$(MAKE) -C ../../stage_dcp_housing_database/code all ../output/dcp_housing_database_project_level_25q4.parquet

../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet: check-stage_dob_now_new_building_filings ;

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet

../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet: check-construct_historical_parent_links ;

.PHONY: check-construct_historical_parent_links

check-construct_historical_parent_links:
	$(MAKE) -C ../../construct_historical_parent_links/code all ../output/historical_parent_filing_link_fields.parquet

include ../../shared/code/generic.make
