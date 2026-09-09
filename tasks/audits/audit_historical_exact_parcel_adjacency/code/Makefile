include ../../../shared/code/shell_functions.make

START_YEAR := 2019
END_YEAR := 2023
MAX_FILING_DAYS := 365
CORROBORATION_DAYS := 30
NEAR_TOUCH_METERS := 1

all: ../output/historical_polygon_adjacency_pairs.parquet \
	../output/historical_exact_adjacency_pairs.csv \
	../output/historical_polygon_adjacency_characteristics.csv \
	../output/historical_polygon_adjacency_release_summary.csv \
	../output/historical_polygon_adjacency_grouping_sensitivity.csv \
	../output/historical_polygon_adjacency_qc.csv

../output/historical_polygon_adjacency_pairs.parquet: audit_historical_exact_parcel_adjacency.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/historical_parent_filing_link_fields.parquet \
	../input/historical_parent_candidate_pairs.parquet ../input/mappluto_files.csv \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< $(START_YEAR) $(END_YEAR) $(MAX_FILING_DAYS) $(CORROBORATION_DAYS) $(NEAR_TOUCH_METERS)

../output/historical_exact_adjacency_pairs.csv \
	../output/historical_polygon_adjacency_characteristics.csv \
	../output/historical_polygon_adjacency_release_summary.csv \
	../output/historical_polygon_adjacency_grouping_sensitivity.csv \
	../output/historical_polygon_adjacency_qc.csv: ../output/historical_polygon_adjacency_pairs.parquet
	$(MAKE) -W audit_historical_exact_parcel_adjacency.R all

../input/historical_parent_filing_link_fields.parquet: ../../audit_historical_parent_link_feasibility/output/historical_parent_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_candidate_pairs.parquet: ../../audit_historical_parent_link_feasibility/output/historical_parent_candidate_pairs.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_files.csv: ../../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/historical_parent_filing_link_fields.parquet \
	../input/historical_parent_candidate_pairs.parquet \
	../input/mappluto_files.csv

../../audit_historical_parent_link_feasibility/output/historical_parent_filing_link_fields.parquet \
	../../audit_historical_parent_link_feasibility/output/historical_parent_candidate_pairs.parquet: check-audit_historical_parent_link_feasibility ;

.PHONY: check-audit_historical_parent_link_feasibility

check-audit_historical_parent_link_feasibility:
	$(MAKE) -C ../../audit_historical_parent_link_feasibility/code all ../output/historical_parent_filing_link_fields.parquet ../output/historical_parent_candidate_pairs.parquet

../../../fetch_mappluto_archive/output/mappluto_files.csv: check-fetch_mappluto_archive ;

.PHONY: check-fetch_mappluto_archive

check-fetch_mappluto_archive:
	$(MAKE) -C ../../../fetch_mappluto_archive/code all ../output/mappluto_files.csv

include ../../../shared/code/generic.make
