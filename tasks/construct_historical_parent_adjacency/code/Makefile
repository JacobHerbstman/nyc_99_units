SHELL := bash
include ../../shell_functions.make

START_YEAR := 2019
END_YEAR := 2023
MAX_FILING_DAYS := 365
CORROBORATION_DAYS := 30

all: ../output/historical_polygon_adjacency_pairs.parquet

../output/historical_polygon_adjacency_pairs.parquet: construct_historical_parent_adjacency.R \
	../../_lib/source_pipeline_utils.R \
	../input/historical_parent_filing_link_fields.parquet \
	../input/historical_parent_candidate_pairs.parquet \
	../input/mappluto_files.csv | ../output
	$(R) $< $(START_YEAR) $(END_YEAR) $(MAX_FILING_DAYS) $(CORROBORATION_DAYS)

../input/historical_parent_filing_link_fields.parquet: ../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_candidate_pairs.parquet: ../../construct_historical_parent_links/output/historical_parent_candidate_pairs.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/historical_parent_filing_link_fields.parquet \
	../input/historical_parent_candidate_pairs.parquet \
	../input/mappluto_files.csv

include ../../generic.make
