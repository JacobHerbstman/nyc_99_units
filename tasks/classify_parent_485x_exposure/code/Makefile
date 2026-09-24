include ../../shared/code/shell_functions.make

AG_CAPTURES := ../input/nys_ag_offering_plan_search_audit_20260826.csv ../input/nys_ag_offering_plan_matches_20260826.csv \
	../input/historical_ag_query_supplement_2019_2022_20260922.csv \
	../input/historical_ag_query_supplement_2023_companions_20260922.csv

all: ../output/parent_485x_exposure_universe.csv ../output/parent_485x_exposure.csv

include ../../shared/code/generic.make

../output/parent_485x_exposure_universe.csv: build_parent_485x_exposure_universe.R \
	../input/symmetric_parent_membership.parquet ../input/historical_parent_filing_link_fields.parquet \
	../input/dcp_housing_database_project_level_23q4.parquet ../input/dcp_housing_database_project_level_25q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet Makefile | $(OOPR)
	$(R) $<

../output/parent_485x_exposure.csv: classify_parent_485x_exposure.R parent_exposure_manual_reviews.csv \
	../output/parent_485x_exposure_universe.csv $(AG_CAPTURES) ../input/hpd_485x_registration_dob_links.csv \
	Makefile | $(OOPR)
	$(R) $<

../input/%.csv: ../../fetch_nys_ag_offering_plans/output/%.csv | ../input
	ln -sf $< $@

../input/symmetric_parent_membership.parquet: \
	../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	ln -sf $< $@

../input/historical_parent_filing_link_fields.parquet: \
	../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet | ../input
	ln -sf $< $@

../input/dcp_housing_database_project_level_%.parquet: \
	../../stage_dcp_housing_database/output/dcp_housing_database_project_level_%.parquet | ../input
	ln -sf $< $@

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@

../input/hpd_485x_registration_dob_links.csv: \
	../../link_hpd_485x_registrations/output/hpd_485x_registration_dob_links.csv | ../input
	ln -sf $< $@
