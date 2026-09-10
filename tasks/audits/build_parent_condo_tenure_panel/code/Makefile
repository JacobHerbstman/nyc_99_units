include ../../../shared/code/shell_functions.make

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

../output/parent_condo_tenure_panel.csv: build_parent_condo_tenure_panel.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/symmetric_parent_membership.parquet \
	../input/dcp_housing_database_project_level_25q4.parquet ../input/dob_now_new_building_initial_filings.parquet \
	../input/historical_parent_filing_link_fields.parquet ../input/nys_ag_offering_plan_search_audit.csv \
	../input/nys_ag_offering_plan_matches.csv ../input/hpd_485x_registration_dob_links.csv \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< $(PRE_START_YEAR) $(PRE_END_YEAR) $(POST_START_DATE) \
		$(MIN_UNITS) $(PREFILING_MATCH_DAYS) \
		$(POSTFILING_MATCH_DAYS) $(FOLLOWUP_DAYS)

../output/parent_condo_counts_by_cohort_year.csv \
../output/parent_condo_counts_by_period.csv \
../output/condo_plan_parent_assignment_review.csv \
../output/parent_condo_tenure_qc.csv: ../output/parent_condo_tenure_panel.csv
	$(RECOVER) -W build_parent_condo_tenure_panel.R all

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_housing_database_project_level_25q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_filing_link_fields.parquet: ../../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nys_ag_offering_plan_search_audit.csv: ../../../classify_parent_485x_exposure/output/nys_ag_offering_plan_search_audit.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nys_ag_offering_plan_matches.csv: ../../../classify_parent_485x_exposure/output/nys_ag_offering_plan_matches.csv | ../input
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

../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet: check-construct_parent_cohorts ;

.PHONY: check-construct_parent_cohorts

check-construct_parent_cohorts:
	$(MAKE) -C ../../../construct_parent_cohorts/code all ../output/symmetric_parent_membership.parquet

../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet: check-stage_dcp_housing_database ;

.PHONY: check-stage_dcp_housing_database

check-stage_dcp_housing_database:
	$(MAKE) -C ../../../stage_dcp_housing_database/code all ../output/dcp_housing_database_project_level_25q4.parquet

../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet: check-stage_dob_now_new_building_filings ;

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet

../../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet: check-construct_historical_parent_links ;

.PHONY: check-construct_historical_parent_links

check-construct_historical_parent_links:
	$(MAKE) -C ../../../construct_historical_parent_links/code all ../output/historical_parent_filing_link_fields.parquet

../../../classify_parent_485x_exposure/output/nys_ag_offering_plan_search_audit.csv \
	../../../classify_parent_485x_exposure/output/nys_ag_offering_plan_matches.csv: check-classify_parent_485x_exposure ;

.PHONY: check-classify_parent_485x_exposure

check-classify_parent_485x_exposure:
	$(MAKE) -C ../../../classify_parent_485x_exposure/code all ../output/nys_ag_offering_plan_search_audit.csv ../output/nys_ag_offering_plan_matches.csv

../../../link_hpd_485x_registrations/output/hpd_485x_registration_dob_links.csv: check-link_hpd_485x_registrations ;

.PHONY: check-link_hpd_485x_registrations

check-link_hpd_485x_registrations:
	$(MAKE) -C ../../../link_hpd_485x_registrations/code all ../output/hpd_485x_registration_dob_links.csv

include ../../../shared/code/generic.make
