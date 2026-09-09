include ../../../shared/code/shell_functions.make

all: ../output/linkage_by_cohort.csv \
	../output/link_signal_availability_by_filing_year.csv \
	../output/linkage_geometry_dependence_by_cohort.csv \
	../output/adjacency_only_link_review.csv \
	../output/geometry_dependent_parent_review.csv \
	../output/tail_relevant_parent_review_validation.csv

../output/linkage_by_cohort.csv: audit_historical_parent_linkage.R Makefile tail_relevant_parent_reviews.csv \
	../../../shared/code/source_pipeline_utils.R ../input/symmetric_parent_membership.parquet \
	../input/symmetric_parent_links.parquet ../input/historical_parent_filing_link_fields.parquet \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/link_signal_availability_by_filing_year.csv \
../output/linkage_geometry_dependence_by_cohort.csv \
../output/adjacency_only_link_review.csv \
../output/geometry_dependent_parent_review.csv \
../output/tail_relevant_parent_review_validation.csv: ../output/linkage_by_cohort.csv
	$(MAKE) -W audit_historical_parent_linkage.R all

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_links.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_links.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_filing_link_fields.parquet: ../../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/symmetric_parent_membership.parquet \
	../input/symmetric_parent_links.parquet \
	../input/historical_parent_filing_link_fields.parquet

../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet \
	../../../construct_parent_cohorts/output/symmetric_parent_links.parquet: check-construct_parent_cohorts ;

.PHONY: check-construct_parent_cohorts

check-construct_parent_cohorts:
	$(MAKE) -C ../../../construct_parent_cohorts/code all ../output/symmetric_parent_membership.parquet ../output/symmetric_parent_links.parquet

../../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet: check-construct_historical_parent_links ;

.PHONY: check-construct_historical_parent_links

check-construct_historical_parent_links:
	$(MAKE) -C ../../../construct_historical_parent_links/code all ../output/historical_parent_filing_link_fields.parquet

include ../../../shared/code/generic.make
