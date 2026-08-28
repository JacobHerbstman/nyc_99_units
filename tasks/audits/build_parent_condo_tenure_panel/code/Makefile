SHELL := bash
include ../../../shell_functions.make

PRE_START_YEAR := 2011
PRE_END_YEAR := 2022
POST_START_DATE := 2023-01-01
MIN_UNITS := 6
PREFILING_MATCH_DAYS := 730
POSTFILING_MATCH_DAYS := 1826
FOLLOWUP_DAYS := 190,365,730

all: ../output/parent_condo_tenure_panel.csv \
	../output/parent_condo_counts_by_cohort_year.csv \
	../output/parent_condo_counts_by_period.csv \
	../output/condo_plan_parent_assignment_review.csv \
	../output/parent_condo_tenure_qc.csv

../output/parent_condo_tenure_panel.csv: build_parent_condo_tenure_panel.R \
	Makefile \
	../../../_lib/source_pipeline_utils.R \
	../input/symmetric_parent_membership.parquet \
	../input/dcp_housing_database_project_level_25q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/historical_parent_filing_link_fields.parquet \
	../input/nys_ag_offering_plan_search_audit.csv \
	../input/nys_ag_offering_plan_matches.csv \
	../input/hpd_485x_registration_dob_links.csv | ../output
	$(R) $< $(PRE_START_YEAR) $(PRE_END_YEAR) $(POST_START_DATE) \
		$(MIN_UNITS) $(PREFILING_MATCH_DAYS) \
		$(POSTFILING_MATCH_DAYS) $(FOLLOWUP_DAYS)

../output/parent_condo_counts_by_cohort_year.csv \
../output/parent_condo_counts_by_period.csv \
../output/condo_plan_parent_assignment_review.csv \
../output/parent_condo_tenure_qc.csv: ../output/parent_condo_tenure_panel.csv
	@test -s "$@"

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_housing_database_project_level_25q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_filing_link_fields.parquet: ../../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nys_ag_offering_plan_search_audit.csv: ../../fetch_nys_ag_offering_plan_matches/output/nys_ag_offering_plan_search_audit.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nys_ag_offering_plan_matches.csv: ../../fetch_nys_ag_offering_plan_matches/output/nys_ag_offering_plan_matches.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hpd_485x_registration_dob_links.csv: ../../../link_hpd_485x_registrations/output/hpd_485x_registration_dob_links.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/symmetric_parent_membership.parquet \
	../input/dcp_housing_database_project_level_25q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/historical_parent_filing_link_fields.parquet \
	../input/nys_ag_offering_plan_search_audit.csv \
	../input/nys_ag_offering_plan_matches.csv \
	../input/hpd_485x_registration_dob_links.csv

include ../../generic.make
