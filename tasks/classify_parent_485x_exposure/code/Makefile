include ../../shared/code/shell_functions.make

all: ../output/nys_ag_offering_plan_search_audit.csv ../output/nys_ag_offering_plan_matches.csv \
	../output/parent_485x_exposure_universe.csv ../output/parent_485x_exposure.csv

include ../../shared/code/generic.make

../output/parent_485x_exposure.csv: classify_parent_485x_exposure.R parent_exposure_manual_reviews.csv \
	../../shared/code/source_pipeline_utils.R ../output/parent_485x_exposure_universe.csv \
	../output/nys_ag_offering_plan_search_audit.csv ../output/nys_ag_offering_plan_matches.csv \
	../input/historical_ag_query_supplement_2019_2022.csv \
	../input/historical_ag_query_supplement_2023_companions.csv \
	../input/hpd_485x_registration_dob_links.csv Makefile ../../shared/code/write_data_report.R | $(OOPR)
	printf '%s  %s\n' 0908af7cd2b41f2ba032d349b5c35a1e15c8f7e16dd0d866ea2019bfa091715f ../input/historical_ag_query_supplement_2019_2022.csv | shasum -a 256 -c -
	printf '%s  %s\n' 0c085614d7dcdb28564a0af4eb009af51c158c85495f08653cfc9b3e7dbe7e2d ../input/historical_ag_query_supplement_2023_companions.csv | shasum -a 256 -c -
	$(R) $<

../output/parent_485x_exposure_universe.csv: build_parent_485x_exposure_universe.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/symmetric_parent_membership.parquet \
	../input/dcp_housing_database_project_level_23q4.parquet \
	../input/dcp_housing_database_project_level_25q4.parquet ../input/dob_now_new_building_initial_filings.parquet \
	../input/historical_parent_filing_link_fields.parquet ../../shared/code/write_data_report.R | $(OOPR)
	$(R) $< 2011 2022 2023-01-01 6

../output/nys_ag_offering_plan_search_audit.csv: \
	../../../data_raw/nys_ag_offering_plan_matches/2026-08-26/nys_ag_offering_plan_search_audit.csv Makefile \
	../../shared/code/copy_data.R ../../shared/code/write_data_report.R | $(OOPR)
	printf '%s  %s\n' 57a5097e9c3f35e1c3ec439eb2576251b87c14d04bee7f01dfe80e461800be0e $< | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

../output/nys_ag_offering_plan_matches.csv: \
	../../../data_raw/nys_ag_offering_plan_matches/2026-08-26/nys_ag_offering_plan_matches.csv Makefile \
	../../shared/code/copy_data.R ../../shared/code/write_data_report.R | $(OOPR)
	printf '%s  %s\n' 1703b417d18cdc0f094531dc3f22b5e2f45fa9ec5161c8a402a2b859f4d56da2 $< | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

../input/historical_ag_query_supplement_2019_2022.csv: \
	../../../data_raw/nys_ag_offering_plan_matches/2026-09-22/historical_ag_query_supplement_2019_2022.csv | ../input
	ln -sf $< $@

../input/historical_ag_query_supplement_2023_companions.csv: \
	../../../data_raw/nys_ag_offering_plan_matches/2026-09-22/historical_ag_query_supplement_2023_companions.csv | ../input
	ln -sf $< $@

../input/hpd_485x_registration_dob_links.csv: \
	../../link_hpd_485x_registrations/output/hpd_485x_registration_dob_links.csv | ../input
	ln -sf $< $@

../input/symmetric_parent_membership.parquet: \
	../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	ln -sf $< $@

../input/dcp_housing_database_project_level_25q4.parquet: \
	../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet | ../input
	ln -sf $< $@

../input/dcp_housing_database_project_level_23q4.parquet: \
	../../stage_dcp_housing_database/output/dcp_housing_database_project_level_23q4.parquet | ../input
	ln -sf $< $@

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@

../input/historical_parent_filing_link_fields.parquet: \
	../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet | ../input
	ln -sf $< $@
