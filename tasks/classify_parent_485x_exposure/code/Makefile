include ../../shared/code/shell_functions.make

PRE_START_YEAR := 2011

PRE_END_YEAR := 2022

POST_START_DATE := 2023-01-01

MIN_UNITS := 6

ifneq ($(filter command,$(origin PRE_START_YEAR) $(origin PRE_END_YEAR) $(origin POST_START_DATE) $(origin MIN_UNITS)),)

$(error These fixed-name outputs use the settings recorded in this Makefile; edit those settings here so Make tracks the change)

endif

all: ../output/parent_485x_exposure.csv ../report/parent_485x_exposure.txt \
	../output/parent_485x_exposure_universe.csv ../report/parent_485x_exposure_universe.txt \
	../output/nys_ag_offering_plan_search_audit.csv ../output/nys_ag_offering_plan_matches.csv \
	../report/nys_ag_offering_plan_matches.txt ../report/nys_ag_offering_plan_search_audit.txt

../output/parent_485x_exposure.csv: classify_parent_485x_exposure.R parent_exposure_manual_reviews.csv \
	../../shared/code/source_pipeline_utils.R ../output/parent_485x_exposure_universe.csv \
	../output/nys_ag_offering_plan_search_audit.csv ../output/nys_ag_offering_plan_matches.csv \
	../input/hpd_485x_registration_dob_links.csv Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../output
	$(R) $<

../report/parent_485x_exposure.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/parent_485x_exposure.csv Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_485x_exposure

../output/parent_485x_exposure_universe.csv: build_parent_485x_exposure_universe.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/symmetric_parent_membership.parquet \
	../input/dcp_housing_database_project_level_25q4.parquet ../input/dob_now_new_building_initial_filings.parquet \
	../input/historical_parent_filing_link_fields.parquet ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../output
	$(R) $< $(PRE_START_YEAR) $(PRE_END_YEAR) $(POST_START_DATE) \
		$(MIN_UNITS)

../report/parent_485x_exposure_universe.txt: report_data.R \
	../../shared/code/write_data_report.R ../output/parent_485x_exposure_universe.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< parent_485x_exposure_universe

../output/nys_ag_offering_plan_search_audit.csv: \
	../../../data_raw/nys_ag_offering_plan_matches/2026-08-26/nys_ag_offering_plan_search_audit.csv Makefile | \
	../output
	printf '%s  %s\n' 57a5097e9c3f35e1c3ec439eb2576251b87c14d04bee7f01dfe80e461800be0e $< | shasum -a 256 -c -
	cp $< $@

../output/nys_ag_offering_plan_matches.csv: \
	../../../data_raw/nys_ag_offering_plan_matches/2026-08-26/nys_ag_offering_plan_matches.csv Makefile | ../output
	printf '%s  %s\n' 1703b417d18cdc0f094531dc3f22b5e2f45fa9ec5161c8a402a2b859f4d56da2 $< | shasum -a 256 -c -
	cp $< $@

../report/nys_ag_offering_plan_matches.txt: report_data.R \
	../../shared/code/write_data_report.R ../output/nys_ag_offering_plan_matches.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< nys_ag_offering_plan_matches

../report/nys_ag_offering_plan_search_audit.txt: report_data.R \
	../../shared/code/write_data_report.R ../output/nys_ag_offering_plan_search_audit.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< nys_ag_offering_plan_search_audit

../input/hpd_485x_registration_dob_links.csv: \
	../../link_hpd_485x_registrations/output/hpd_485x_registration_dob_links.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_membership.parquet: \
	../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_housing_database_project_level_25q4.parquet: \
	../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_filing_link_fields.parquet: \
	../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

.PHONY: check-link_hpd_485x_registrations

check-link_hpd_485x_registrations:
	$(MAKE) -C ../../link_hpd_485x_registrations/code all ../output/hpd_485x_registration_dob_links.csv

.PHONY: check-construct_parent_cohorts

check-construct_parent_cohorts:
	$(MAKE) -C ../../construct_parent_cohorts/code all ../output/symmetric_parent_membership.parquet

.PHONY: check-stage_dcp_housing_database

check-stage_dcp_housing_database:
	$(MAKE) -C ../../stage_dcp_housing_database/code all ../output/dcp_housing_database_project_level_25q4.parquet

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet

.PHONY: check-construct_historical_parent_links

check-construct_historical_parent_links:
	$(MAKE) -C ../../construct_historical_parent_links/code all ../output/historical_parent_filing_link_fields.parquet

../../link_hpd_485x_registrations/output/hpd_485x_registration_dob_links.csv: check-link_hpd_485x_registrations ;

../../construct_parent_cohorts/output/symmetric_parent_membership.parquet: check-construct_parent_cohorts ;

../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet: check-stage_dcp_housing_database ;

../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet: check-stage_dob_now_new_building_filings ;

../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet: check-construct_historical_parent_links ;

link-inputs: ../input/hpd_485x_registration_dob_links.csv ../input/symmetric_parent_membership.parquet \
	../input/dcp_housing_database_project_level_25q4.parquet ../input/dob_now_new_building_initial_filings.parquet \
	../input/historical_parent_filing_link_fields.parquet

include ../../shared/code/generic.make
