include ../../../shared/code/shell_functions.make

POST_YEAR := 2025
MIN_UNITS := 6

all: ../output/hdb_dob_identifier_later_same_site_candidates.csv ../output/hdb_dob_identifier_handoff.csv \
	../output/hdb_dob_identifier_review.csv \
	\
	../output/hdb_dob_identifier_summary.csv

../output/hdb_dob_identifier_later_same_site_candidates.csv: audit_hdb_dob_identifier_handoff.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/hdb_mappluto_site_panel.parquet \
	../input/dob_now_new_building_initial_filings.parquet ../input/post_policy_filing_link_fields.parquet \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | \
	../output
	$(R) $< $(POST_YEAR) $(MIN_UNITS)

../output/hdb_dob_identifier_handoff.csv \
	../output/hdb_dob_identifier_review.csv \
	../output/hdb_dob_identifier_summary.csv: ../output/hdb_dob_identifier_later_same_site_candidates.csv
	$(RECOVER) -W audit_hdb_dob_identifier_handoff.R all

../input/hdb_mappluto_site_panel.parquet: ../../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_filing_link_fields.parquet: ../../../construct_parent_cohorts/output/post_policy_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_site_panel.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/post_policy_filing_link_fields.parquet

../../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet: check-build_hdb_mappluto_site_panel ;

.PHONY: check-build_hdb_mappluto_site_panel

check-build_hdb_mappluto_site_panel:
	$(MAKE) -C ../../../build_hdb_mappluto_site_panel/code all ../output/hdb_mappluto_site_panel.parquet

../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet: check-stage_dob_now_new_building_filings ;

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet

../../../construct_parent_cohorts/output/post_policy_filing_link_fields.parquet: check-construct_parent_cohorts ;

.PHONY: check-construct_parent_cohorts

check-construct_parent_cohorts:
	$(MAKE) -C ../../../construct_parent_cohorts/code all ../output/post_policy_filing_link_fields.parquet

include ../../../shared/code/generic.make
