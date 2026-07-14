SHELL := bash
include ../../../shell_functions.make

ANCHOR_YEAR := 2025
COMPANION_START_YEAR := 2024
COMPANION_END_YEAR := 2026
MIN_COMPANION_UNITS := 6
MAX_COMPANION_UNITS := 1000
BUNCHING_UNITS := 99
NEARBY_METERS := 100
REVIEW_METERS := 250
MAX_FILING_DAYS := 365

all: ../output/developer_opportunity_job_crosswalk.parquet \
	../output/developer_opportunity_candidate_pairs.csv \
	../output/developer_opportunity_unresolved_pair_review.csv \
	../output/developer_opportunity_candidate_groups.csv \
	../output/developer_opportunity_exact_99_casebook.csv \
	../output/developer_opportunity_bunching_decomposition.csv \
	../output/developer_opportunity_crosswalk_qc.csv

../output/developer_opportunity_job_crosswalk.parquet: audit_developer_opportunity_crosswalk.R ../../../_lib/source_pipeline_utils.R ../input/dob_now_new_building_filings.parquet ../input/dob_now_new_building_initial_filings.parquet ../input/mappluto_appbbl_crosswalk.csv ../input/developer_response_application_panel.parquet ../input/manual_case_evidence.csv ../input/manual_repeated_99_parent_investigation.csv | ../output
	$(R) $< $(ANCHOR_YEAR) $(COMPANION_START_YEAR) $(COMPANION_END_YEAR) $(MIN_COMPANION_UNITS) $(MAX_COMPANION_UNITS) $(BUNCHING_UNITS) $(NEARBY_METERS) $(REVIEW_METERS) $(MAX_FILING_DAYS)

../output/developer_opportunity_candidate_pairs.csv ../output/developer_opportunity_unresolved_pair_review.csv ../output/developer_opportunity_candidate_groups.csv ../output/developer_opportunity_exact_99_casebook.csv ../output/developer_opportunity_bunching_decomposition.csv ../output/developer_opportunity_crosswalk_qc.csv: ../output/developer_opportunity_job_crosswalk.parquet
	@test -s "$@"

../input/dob_now_new_building_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_appbbl_crosswalk.csv: ../../../build_mappluto_appbbl_crosswalk/output/mappluto_appbbl_crosswalk.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/developer_response_application_panel.parquet: ../../audit_developer_responses/output/developer_response_application_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dob_now_new_building_filings.parquet ../input/dob_now_new_building_initial_filings.parquet ../input/mappluto_appbbl_crosswalk.csv ../input/developer_response_application_panel.parquet

include ../../generic.make
