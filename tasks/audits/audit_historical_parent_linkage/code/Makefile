SHELL := bash
include ../../../shell_functions.make

all: ../output/linkage_by_cohort.csv \
	../output/link_signal_availability_by_filing_year.csv \
	../output/linkage_geometry_dependence_by_cohort.csv \
	../output/adjacency_only_link_review.csv \
	../output/geometry_dependent_parent_review.csv \
	../output/tail_relevant_parent_review_validation.csv

../output/linkage_by_cohort.csv: audit_historical_parent_linkage.R \
	Makefile \
	tail_relevant_parent_reviews.csv \
	../../../_lib/source_pipeline_utils.R \
	../input/symmetric_parent_membership.parquet \
	../input/symmetric_parent_links.parquet \
	../input/historical_parent_filing_link_fields.parquet | ../output
	$(R) $<

../output/link_signal_availability_by_filing_year.csv \
../output/linkage_geometry_dependence_by_cohort.csv \
../output/adjacency_only_link_review.csv \
../output/geometry_dependent_parent_review.csv \
../output/tail_relevant_parent_review_validation.csv: ../output/linkage_by_cohort.csv
	@test -s "$@"

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_links.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_links.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_filing_link_fields.parquet: ../../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/symmetric_parent_membership.parquet \
	../input/symmetric_parent_links.parquet \
	../input/historical_parent_filing_link_fields.parquet

include ../../generic.make
