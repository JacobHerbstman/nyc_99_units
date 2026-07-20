SHELL := bash
include ../../../shell_functions.make

POST_COHORT_YEAR := 2025

all: ../output/symmetric_parent_cohort_inventory.csv \
	../output/symmetric_parent_2025_exact_99_paths.csv \
	../output/symmetric_parent_2025_exact_99_paths_dob_i1.csv \
	../output/symmetric_parent_link_summary.csv \
	../output/symmetric_parent_cohort_summary.csv \
	../output/symmetric_parent_cohort_qc.csv

../output/symmetric_parent_cohort_inventory.csv: audit_symmetric_parent_cohorts.R \
	../../../_lib/source_pipeline_utils.R \
	../input/symmetric_parent_membership.parquet \
	../input/symmetric_parent_links.parquet | ../output
	$(R) $< $(POST_COHORT_YEAR)

../output/symmetric_parent_2025_exact_99_paths.csv \
../output/symmetric_parent_2025_exact_99_paths_dob_i1.csv \
../output/symmetric_parent_link_summary.csv \
../output/symmetric_parent_cohort_summary.csv \
../output/symmetric_parent_cohort_qc.csv: ../output/symmetric_parent_cohort_inventory.csv
	@test -s "$@"

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_links.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_links.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/symmetric_parent_membership.parquet \
	../input/symmetric_parent_links.parquet

include ../../generic.make
