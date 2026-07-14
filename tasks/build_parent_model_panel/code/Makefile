SHELL := bash
include ../../shell_functions.make

PRE_START_YEAR := 2019
PRE_END_YEAR := 2023
POST_YEAR := 2025
MIN_UNITS := 6
MAX_FILING_DAYS := 365
CORROBORATION_DAYS := 30

all: ../output/historical_enhanced_parent_model_panel.parquet \
	../output/post_policy_enhanced_parent_model_panel.parquet

../output/historical_enhanced_parent_model_panel.parquet: build_parent_model_panel.R \
	../../_lib/source_pipeline_utils.R \
	../input/hdb_mappluto_training_panel.parquet \
	../input/historical_parent_candidate_pairs.parquet \
	../input/historical_polygon_adjacency_pairs.parquet \
	../input/post_policy_filing_link_fields.parquet \
	../input/mappluto_files.csv | ../output
	$(R) $< $(PRE_START_YEAR) $(PRE_END_YEAR) $(POST_YEAR) $(MIN_UNITS) $(MAX_FILING_DAYS) $(CORROBORATION_DAYS)

../output/post_policy_enhanced_parent_model_panel.parquet: ../output/historical_enhanced_parent_model_panel.parquet
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_candidate_pairs.parquet: ../../construct_historical_parent_links/output/historical_parent_candidate_pairs.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_polygon_adjacency_pairs.parquet: ../../construct_historical_parent_adjacency/output/historical_polygon_adjacency_pairs.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_filing_link_fields.parquet: ../../construct_post_policy_parent_crosswalk/output/post_policy_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet \
	../input/historical_parent_candidate_pairs.parquet \
	../input/historical_polygon_adjacency_pairs.parquet \
	../input/post_policy_filing_link_fields.parquet \
	../input/mappluto_files.csv

include ../../generic.make
