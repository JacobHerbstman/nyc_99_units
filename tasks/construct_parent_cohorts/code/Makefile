SHELL := bash
include ../../shell_functions.make

HISTORICAL_LINK_START_YEAR := 2010
HISTORICAL_COHORT_START_YEAR := 2011
HISTORICAL_END_YEAR := 2023
POST_COMPARISON_START_YEAR := 2023
POST_COHORT_YEAR := 2025
MAX_FILING_DAYS := 365
CORROBORATION_DAYS := 30
POST_GEOMETRY_VINTAGE := 23v3.1

all: ../output/symmetric_parent_membership.parquet \
	../output/symmetric_parent_links.parquet

../output/symmetric_parent_membership.parquet: construct_parent_cohorts.R \
	historical_parent_link_reviews.csv \
	Makefile \
	../../_lib/source_pipeline_utils.R \
	../input/historical_parent_filing_link_fields.parquet \
	../input/historical_parent_candidate_pairs.parquet \
	../input/historical_polygon_adjacency_pairs.parquet \
	../input/historical_polygon_geometry_coverage.parquet \
	../input/post_policy_filing_link_fields.parquet \
	../input/hdb_mappluto_training_panel.parquet \
	../input/mappluto_files.csv | ../output
	$(R) $< $(HISTORICAL_LINK_START_YEAR) \
		$(HISTORICAL_COHORT_START_YEAR) $(HISTORICAL_END_YEAR) \
		$(POST_COMPARISON_START_YEAR) $(POST_COHORT_YEAR) \
		$(MAX_FILING_DAYS) $(CORROBORATION_DAYS) \
		$(POST_GEOMETRY_VINTAGE)

../output/symmetric_parent_links.parquet: ../output/symmetric_parent_membership.parquet
	@test -s "$@"

../input/historical_parent_filing_link_fields.parquet: ../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_candidate_pairs.parquet: ../../construct_historical_parent_links/output/historical_parent_candidate_pairs.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_polygon_adjacency_pairs.parquet: ../../construct_historical_parent_adjacency/output/historical_polygon_adjacency_pairs.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_polygon_geometry_coverage.parquet: ../../construct_historical_parent_adjacency/output/historical_polygon_geometry_coverage.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_filing_link_fields.parquet: ../../construct_post_policy_parent_crosswalk/output/post_policy_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hdb_mappluto_training_panel.parquet: ../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/historical_parent_filing_link_fields.parquet \
	../input/historical_parent_candidate_pairs.parquet \
	../input/historical_polygon_adjacency_pairs.parquet \
	../input/historical_polygon_geometry_coverage.parquet \
	../input/post_policy_filing_link_fields.parquet \
	../input/hdb_mappluto_training_panel.parquet \
	../input/mappluto_files.csv

include ../../generic.make
