SHELL := bash
include ../../../shell_functions.make

POST_YEAR := 2025
MIN_UNITS := 6

all: ../output/hdb_dob_identifier_handoff.csv \
	../output/hdb_dob_identifier_review.csv \
	../output/hdb_dob_identifier_later_same_site_candidates.csv \
	../output/hdb_dob_identifier_summary.csv

../output/hdb_dob_identifier_handoff.csv: audit_hdb_dob_identifier_handoff.R \
	../../../_lib/source_pipeline_utils.R \
	../input/hdb_mappluto_site_panel.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/post_policy_filing_link_fields.parquet | ../output
	$(R) $< $(POST_YEAR) $(MIN_UNITS)

../output/hdb_dob_identifier_review.csv \
../output/hdb_dob_identifier_later_same_site_candidates.csv \
../output/hdb_dob_identifier_summary.csv: ../output/hdb_dob_identifier_handoff.csv
	@test -s "$@"

../input/hdb_mappluto_site_panel.parquet: ../../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_filing_link_fields.parquet: ../../../construct_post_policy_parent_crosswalk/output/post_policy_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_site_panel.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/post_policy_filing_link_fields.parquet

include ../../generic.make
