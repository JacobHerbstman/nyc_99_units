include ../../../shared/code/shell_functions.make

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

../output/symmetric_parent_cohort_inventory.csv: audit_symmetric_parent_cohorts.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/post_parent_reviews.csv \
	../input/pair_decisions.csv \
	../input/post_parent_filing_roles.csv \
	../input/symmetric_parent_membership.parquet ../input/symmetric_parent_links.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< $(POST_COHORT_YEAR)

../output/symmetric_parent_2025_exact_99_paths.csv \
../output/symmetric_parent_2025_exact_99_paths_dob_i1.csv \
../output/post_site_linkage_bbl_links.csv \
../output/post_site_linkage_bbl_parent_review.csv \
../output/post_parent_review_decisions.csv \
../output/symmetric_parent_link_summary.csv \
../output/symmetric_parent_cohort_summary.csv \
../output/symmetric_parent_cohort_qc.csv: ../output/symmetric_parent_cohort_inventory.csv
	$(MAKE) -W audit_symmetric_parent_cohorts.R all

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_links.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_links.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_parent_reviews.csv: ../../../parent_opportunities_manual/output/post_parent_reviews.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/pair_decisions.csv: ../../../parent_opportunities_manual/output/pair_decisions.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_parent_filing_roles.csv: ../../../parent_opportunities_manual/output/post_parent_filing_roles.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/post_parent_reviews.csv ../input/pair_decisions.csv ../input/post_parent_filing_roles.csv \
	../input/symmetric_parent_membership.parquet \
	../input/symmetric_parent_links.parquet \
	../input/dob_now_new_building_initial_filings.parquet

../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet \
	../../../construct_parent_cohorts/output/symmetric_parent_links.parquet: check-construct_parent_cohorts ;

.PHONY: check-construct_parent_cohorts

check-construct_parent_cohorts:
	$(MAKE) -C ../../../construct_parent_cohorts/code all ../output/symmetric_parent_membership.parquet ../output/symmetric_parent_links.parquet

../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet: check-stage_dob_now_new_building_filings ;

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet

include ../../../shared/code/generic.make
