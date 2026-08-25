SHELL := bash
include ../../../shell_functions.make

POST_YEAR := 2025
BUNCHING_UNITS := 99
THRESHOLD_UNITS := 100

all: ../output/hpd_485x_registration_dob_links.csv \
	../output/hpd_485x_exact_99_buildings.csv \
	../output/hpd_485x_parent_registration_summary.csv

../output/hpd_485x_registration_dob_links.csv: audit_hpd_485x_registration_linkage.R \
	../input/hpd_485x_registrations.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/symmetric_parent_membership.parquet \
	../input/enhanced_parent_2025_scores.parquet \
	../input/developer_opportunity_job_crosswalk.parquet | ../output
	$(R) $< $(POST_YEAR) $(BUNCHING_UNITS) $(THRESHOLD_UNITS)

../output/hpd_485x_exact_99_buildings.csv \
../output/hpd_485x_parent_registration_summary.csv: ../output/hpd_485x_registration_dob_links.csv
	@test -s "$@"

../input/hpd_485x_registrations.parquet: ../../../stage_hpd_485x_registrations/output/hpd_485x_registrations.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/enhanced_parent_2025_scores.parquet: ../../../estimate_parent_no_notch_model/output/enhanced_parent_2025_scores.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/developer_opportunity_job_crosswalk.parquet: ../../audit_developer_opportunity_crosswalk/output/developer_opportunity_job_crosswalk.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hpd_485x_registrations.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/symmetric_parent_membership.parquet \
	../input/enhanced_parent_2025_scores.parquet \
	../input/developer_opportunity_job_crosswalk.parquet

include ../../generic.make
