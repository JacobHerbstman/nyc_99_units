SHELL := bash
include ../../../shell_functions.make

POST_COHORT_YEAR := 2025

all: ../output/symmetric_parent_cohort_inventory.csv \
	../output/symmetric_parent_2025_exact_99_paths.csv \
	../output/symmetric_parent_2025_exact_99_paths_dob_i1.csv \
	../output/post_site_linkage_bbl_links.csv \
	../output/post_site_linkage_bbl_parent_review.csv \
	../output/post_parent_review_decisions.csv \
	../output/symmetric_parent_link_summary.csv \
	../output/symmetric_parent_cohort_summary.csv \
	../output/symmetric_parent_cohort_qc.csv

../output/symmetric_parent_cohort_inventory.csv: audit_symmetric_parent_cohorts.R \
	../../../_lib/source_pipeline_utils.R \
	../../../construct_parent_cohorts/code/post_parent_reviews.csv \
	../../../construct_parent_cohorts/code/post_parent_link_reviews.csv \
	../../../construct_parent_cohorts/code/post_parent_filing_roles.csv \
	../input/symmetric_parent_membership.parquet \
	../input/symmetric_parent_links.parquet \
	../input/dob_now_new_building_initial_filings.parquet | ../output
	$(R) $< $(POST_COHORT_YEAR)

../output/symmetric_parent_2025_exact_99_paths.csv \
../output/symmetric_parent_2025_exact_99_paths_dob_i1.csv \
../output/post_site_linkage_bbl_links.csv \
../output/post_site_linkage_bbl_parent_review.csv \
../output/post_parent_review_decisions.csv \
../output/symmetric_parent_link_summary.csv \
../output/symmetric_parent_cohort_summary.csv \
../output/symmetric_parent_cohort_qc.csv: ../output/symmetric_parent_cohort_inventory.csv
	@test -s "$@"

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_links.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_links.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/symmetric_parent_membership.parquet \
	../input/symmetric_parent_links.parquet \
	../input/dob_now_new_building_initial_filings.parquet

include ../../generic.make
