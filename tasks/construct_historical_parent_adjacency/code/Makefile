include ../../shared/code/shell_functions.make

START_YEAR := 2010
END_YEAR := 2023
MAX_FILING_DAYS := 365
CORROBORATION_DAYS := 30

ifneq ($(filter command,$(origin START_YEAR) $(origin END_YEAR) $(origin MAX_FILING_DAYS) $(origin CORROBORATION_DAYS)),)
$(error These fixed-name outputs use the settings recorded in this Makefile; edit those settings here so Make tracks the change)
endif

all: ../output/historical_polygon_adjacency_pairs.parquet ../output/historical_polygon_geometry_coverage.parquet \
	../report/historical_polygon_adjacency_pairs.txt \
	../report/historical_polygon_geometry_coverage.txt

../output/historical_polygon_adjacency_pairs.parquet: construct_historical_parent_adjacency.R Makefile \
	../input/mappluto_09v1.zip ../input/mappluto_09v2.zip ../input/mappluto_10v1.zip ../input/mappluto_10v2.zip \
	../input/mappluto_11v1.zip ../input/mappluto_11v2.zip ../input/mappluto_12v1.zip ../input/mappluto_12v2.zip \
	../input/mappluto_13v1.zip ../input/mappluto_13v2.zip ../input/mappluto_14v1.zip ../input/mappluto_14v2.zip \
	../input/mappluto_15v1.zip ../input/mappluto_16v1.zip ../input/mappluto_16v2.zip ../input/mappluto_17v1.zip \
	../input/mappluto_17v1_1.zip ../input/nyc_mappluto_18v1_1_arc_shp.zip ../input/nyc_mappluto_18v2_1_arc_shp.zip \
	../input/nyc_mappluto_18v2_arc_shp.zip ../input/nyc_mappluto_19v1_arc_shp.zip \
	../input/nyc_mappluto_19v2_arc_shp.zip ../input/nyc_mappluto_20v1_arc_shp.zip \
	../input/nyc_mappluto_20v2_arc_shp.zip ../input/nyc_mappluto_20v3_arc_shp.zip \
	../input/nyc_mappluto_20v4_arc_shp.zip ../input/nyc_mappluto_20v5_arc_shp.zip \
	../input/nyc_mappluto_20v6_arc_shp.zip ../input/nyc_mappluto_20v7_arc_shp.zip \
	../input/nyc_mappluto_20v8_arc_shp.zip ../input/nyc_mappluto_21v1_arc_shp.zip \
	../input/nyc_mappluto_21v3_arc_shp.zip ../input/nyc_mappluto_22v1_arc_shp.zip \
	../input/nyc_mappluto_22v2_arc_shp.zip ../input/nyc_mappluto_23v1_arc_shp.zip \
	../input/nyc_mappluto_23v1_1_arc_shp.zip ../input/nyc_mappluto_23v1_2_arc_shp.zip \
	../input/nyc_mappluto_23v2_arc_shp.zip ../input/nyc_mappluto_23v3_arc_shp.zip \
	../input/nyc_mappluto_23v3_1_arc_shp.zip ../input/nyc_pluto_09v1.zip ../input/nyc_pluto_09v2.zip \
	../input/nyc_pluto_10v1.zip ../input/nyc_pluto_10v2.zip ../input/nyc_pluto_11v1.zip \
	../input/nyc_pluto_11v2.zip ../input/nyc_pluto_12v1.zip ../input/nyc_pluto_12v2.zip \
	../input/nyc_pluto_13v1.zip ../input/nyc_pluto_13v2.zip ../input/nyc_pluto_14v1.zip \
	../input/nyc_pluto_14v2.zip ../input/nyc_pluto_15v1.zip ../input/nyc_pluto_16v1.zip \
	../input/nyc_pluto_16v2.zip ../input/nyc_pluto_17v1.zip ../input/nyc_pluto_17v1_1.zip \
	../input/nyc_pluto_18v1.zip ../../shared/code/source_pipeline_utils.R \
	../input/historical_parent_filing_link_fields.parquet ../input/historical_parent_candidate_pairs.parquet \
	../input/mappluto_files.csv \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $< $(START_YEAR) $(END_YEAR) $(MAX_FILING_DAYS) $(CORROBORATION_DAYS)

../output/historical_polygon_geometry_coverage.parquet: ../output/historical_polygon_adjacency_pairs.parquet
	$(MAKE) -W construct_historical_parent_adjacency.R all


../report/historical_polygon_adjacency_pairs.txt: report_data.R ../../shared/code/write_data_report.R ../output/historical_polygon_adjacency_pairs.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< historical_polygon_adjacency_pairs

../report/historical_polygon_geometry_coverage.txt: report_data.R ../../shared/code/write_data_report.R ../output/historical_polygon_geometry_coverage.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< historical_polygon_geometry_coverage


../input/historical_parent_filing_link_fields.parquet: ../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_candidate_pairs.parquet: ../../construct_historical_parent_links/output/historical_parent_candidate_pairs.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/historical_parent_filing_link_fields.parquet \
	../input/historical_parent_candidate_pairs.parquet \
	../input/mappluto_files.csv

../input/mappluto_09v1.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_09v1_mappluto_09v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_09v2.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_09v2_mappluto_09v2.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_10v1.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_10v1_mappluto_10v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_10v2.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_10v2_mappluto_10v2.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_11v1.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_11v1_mappluto_11v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_11v2.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_11v2_mappluto_11v2.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_12v1.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_12v1_mappluto_12v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_12v2.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_12v2_mappluto_12v2.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_13v1.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_13v1_mappluto_13v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_13v2.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_13v2_mappluto_13v2.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_14v1.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_14v1_mappluto_14v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_14v2.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_14v2_mappluto_14v2.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_15v1.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_15v1_mappluto_15v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_16v1.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_16v1_mappluto_16v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_16v2.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_16v2_mappluto_16v2.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_17v1.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_17v1_mappluto_17v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_17v1_1.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_17v1.1_mappluto_17v1_1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_18v1_1_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_18v1.1_nyc_mappluto_18v1_1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_18v2_1_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_18v2.1_nyc_mappluto_18v2_1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_18v2_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_18v2Beta_nyc_mappluto_18v2_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_19v1_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_19v1_nyc_mappluto_19v1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_19v2_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_19v2_nyc_mappluto_19v2_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v1_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v1_nyc_mappluto_20v1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v2_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v2_nyc_mappluto_20v2_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v3_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v3_nyc_mappluto_20v3_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v4_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v4_nyc_mappluto_20v4_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v5_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v5_nyc_mappluto_20v5_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v6_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v6_nyc_mappluto_20v6_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v7_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v7_nyc_mappluto_20v7_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v8_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v8_nyc_mappluto_20v8_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_21v1_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_21v1_nyc_mappluto_21v1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_21v3_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_21v3_nyc_mappluto_21v3_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_22v1_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_22v1_nyc_mappluto_22v1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_22v2_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_22v2_nyc_mappluto_22v2_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_23v1_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v1_nyc_mappluto_23v1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_23v1_1_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v1.1_nyc_mappluto_23v1_1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_23v1_2_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v1.2_nyc_mappluto_23v1_2_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_23v2_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v2_nyc_mappluto_23v2_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_23v3_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v3_nyc_mappluto_23v3_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_23v3_1_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v3.1_nyc_mappluto_23v3_1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_09v1.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_09v1_nyc_pluto_09v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_09v2.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_09v2_nyc_pluto_09v2.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_10v1.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_10v1_nyc_pluto_10v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_10v2.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_10v2_nyc_pluto_10v2.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_11v1.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_11v1_nyc_pluto_11v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_11v2.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_11v2_nyc_pluto_11v2.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_12v1.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_12v1_nyc_pluto_12v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_12v2.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_12v2_nyc_pluto_12v2.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_13v1.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_13v1_nyc_pluto_13v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_13v2.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_13v2_nyc_pluto_13v2.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_14v1.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_14v1_nyc_pluto_14v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_14v2.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_14v2_nyc_pluto_14v2.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_15v1.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_15v1_nyc_pluto_15v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_16v1.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_16v1_nyc_pluto_16v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_16v2.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_16v2_nyc_pluto_16v2.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_17v1.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_17v1_nyc_pluto_17v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_17v1_1.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_17v1.1_nyc_pluto_17v1_1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_18v1.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_18v1_nyc_pluto_18v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet \
	../../construct_historical_parent_links/output/historical_parent_candidate_pairs.parquet: check-construct_historical_parent_links ;

.PHONY: check-construct_historical_parent_links

check-construct_historical_parent_links:
	$(MAKE) -C ../../construct_historical_parent_links/code all ../output/historical_parent_filing_link_fields.parquet ../output/historical_parent_candidate_pairs.parquet

../../fetch_mappluto_archive/output/mappluto_files.csv \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_09v1_mappluto_09v1.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_09v2_mappluto_09v2.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_10v1_mappluto_10v1.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_10v2_mappluto_10v2.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_11v1_mappluto_11v1.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_11v2_mappluto_11v2.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_12v1_mappluto_12v1.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_12v2_mappluto_12v2.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_13v1_mappluto_13v1.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_13v2_mappluto_13v2.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_14v1_mappluto_14v1.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_14v2_mappluto_14v2.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_15v1_mappluto_15v1.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_16v1_mappluto_16v1.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_16v2_mappluto_16v2.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_17v1_mappluto_17v1.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_17v1.1_mappluto_17v1_1.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_18v1.1_nyc_mappluto_18v1_1_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_18v2.1_nyc_mappluto_18v2_1_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_18v2Beta_nyc_mappluto_18v2_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_19v1_nyc_mappluto_19v1_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_19v2_nyc_mappluto_19v2_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v1_nyc_mappluto_20v1_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v2_nyc_mappluto_20v2_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v3_nyc_mappluto_20v3_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v4_nyc_mappluto_20v4_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v5_nyc_mappluto_20v5_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v6_nyc_mappluto_20v6_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v7_nyc_mappluto_20v7_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v8_nyc_mappluto_20v8_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_21v1_nyc_mappluto_21v1_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_21v3_nyc_mappluto_21v3_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_22v1_nyc_mappluto_22v1_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_22v2_nyc_mappluto_22v2_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v1_nyc_mappluto_23v1_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v1.1_nyc_mappluto_23v1_1_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v1.2_nyc_mappluto_23v1_2_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v2_nyc_mappluto_23v2_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v3_nyc_mappluto_23v3_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v3.1_nyc_mappluto_23v3_1_arc_shp.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_09v1_nyc_pluto_09v1.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_09v2_nyc_pluto_09v2.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_10v1_nyc_pluto_10v1.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_10v2_nyc_pluto_10v2.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_11v1_nyc_pluto_11v1.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_11v2_nyc_pluto_11v2.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_12v1_nyc_pluto_12v1.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_12v2_nyc_pluto_12v2.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_13v1_nyc_pluto_13v1.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_13v2_nyc_pluto_13v2.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_14v1_nyc_pluto_14v1.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_14v2_nyc_pluto_14v2.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_15v1_nyc_pluto_15v1.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_16v1_nyc_pluto_16v1.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_16v2_nyc_pluto_16v2.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_17v1_nyc_pluto_17v1.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_17v1.1_nyc_pluto_17v1_1.zip \
	../../fetch_mappluto_archive/output/dcp_pluto_archive_18v1_nyc_pluto_18v1.zip: check-fetch_mappluto_archive ;

.PHONY: check-fetch_mappluto_archive

check-fetch_mappluto_archive:
	$(MAKE) -C ../../fetch_mappluto_archive/code all ../output/mappluto_files.csv ../output/dcp_mappluto_archive_09v1_mappluto_09v1.zip ../output/dcp_mappluto_archive_09v2_mappluto_09v2.zip ../output/dcp_mappluto_archive_10v1_mappluto_10v1.zip ../output/dcp_mappluto_archive_10v2_mappluto_10v2.zip ../output/dcp_mappluto_archive_11v1_mappluto_11v1.zip ../output/dcp_mappluto_archive_11v2_mappluto_11v2.zip ../output/dcp_mappluto_archive_12v1_mappluto_12v1.zip ../output/dcp_mappluto_archive_12v2_mappluto_12v2.zip ../output/dcp_mappluto_archive_13v1_mappluto_13v1.zip ../output/dcp_mappluto_archive_13v2_mappluto_13v2.zip ../output/dcp_mappluto_archive_14v1_mappluto_14v1.zip ../output/dcp_mappluto_archive_14v2_mappluto_14v2.zip ../output/dcp_mappluto_archive_15v1_mappluto_15v1.zip ../output/dcp_mappluto_archive_16v1_mappluto_16v1.zip ../output/dcp_mappluto_archive_16v2_mappluto_16v2.zip ../output/dcp_mappluto_archive_17v1_mappluto_17v1.zip ../output/dcp_mappluto_archive_17v1.1_mappluto_17v1_1.zip ../output/dcp_mappluto_archive_18v1.1_nyc_mappluto_18v1_1_arc_shp.zip ../output/dcp_mappluto_archive_18v2.1_nyc_mappluto_18v2_1_arc_shp.zip ../output/dcp_mappluto_archive_18v2Beta_nyc_mappluto_18v2_arc_shp.zip ../output/dcp_mappluto_archive_19v1_nyc_mappluto_19v1_arc_shp.zip ../output/dcp_mappluto_archive_19v2_nyc_mappluto_19v2_arc_shp.zip ../output/dcp_mappluto_archive_20v1_nyc_mappluto_20v1_arc_shp.zip ../output/dcp_mappluto_archive_20v2_nyc_mappluto_20v2_arc_shp.zip ../output/dcp_mappluto_archive_20v3_nyc_mappluto_20v3_arc_shp.zip ../output/dcp_mappluto_archive_20v4_nyc_mappluto_20v4_arc_shp.zip ../output/dcp_mappluto_archive_20v5_nyc_mappluto_20v5_arc_shp.zip ../output/dcp_mappluto_archive_20v6_nyc_mappluto_20v6_arc_shp.zip ../output/dcp_mappluto_archive_20v7_nyc_mappluto_20v7_arc_shp.zip ../output/dcp_mappluto_archive_20v8_nyc_mappluto_20v8_arc_shp.zip ../output/dcp_mappluto_archive_21v1_nyc_mappluto_21v1_arc_shp.zip ../output/dcp_mappluto_archive_21v3_nyc_mappluto_21v3_arc_shp.zip ../output/dcp_mappluto_archive_22v1_nyc_mappluto_22v1_arc_shp.zip ../output/dcp_mappluto_archive_22v2_nyc_mappluto_22v2_arc_shp.zip ../output/dcp_mappluto_archive_23v1_nyc_mappluto_23v1_arc_shp.zip ../output/dcp_mappluto_archive_23v1.1_nyc_mappluto_23v1_1_arc_shp.zip ../output/dcp_mappluto_archive_23v1.2_nyc_mappluto_23v1_2_arc_shp.zip ../output/dcp_mappluto_archive_23v2_nyc_mappluto_23v2_arc_shp.zip ../output/dcp_mappluto_archive_23v3_nyc_mappluto_23v3_arc_shp.zip ../output/dcp_mappluto_archive_23v3.1_nyc_mappluto_23v3_1_arc_shp.zip ../output/dcp_pluto_archive_09v1_nyc_pluto_09v1.zip ../output/dcp_pluto_archive_09v2_nyc_pluto_09v2.zip ../output/dcp_pluto_archive_10v1_nyc_pluto_10v1.zip ../output/dcp_pluto_archive_10v2_nyc_pluto_10v2.zip ../output/dcp_pluto_archive_11v1_nyc_pluto_11v1.zip ../output/dcp_pluto_archive_11v2_nyc_pluto_11v2.zip ../output/dcp_pluto_archive_12v1_nyc_pluto_12v1.zip ../output/dcp_pluto_archive_12v2_nyc_pluto_12v2.zip ../output/dcp_pluto_archive_13v1_nyc_pluto_13v1.zip ../output/dcp_pluto_archive_13v2_nyc_pluto_13v2.zip ../output/dcp_pluto_archive_14v1_nyc_pluto_14v1.zip ../output/dcp_pluto_archive_14v2_nyc_pluto_14v2.zip ../output/dcp_pluto_archive_15v1_nyc_pluto_15v1.zip ../output/dcp_pluto_archive_16v1_nyc_pluto_16v1.zip ../output/dcp_pluto_archive_16v2_nyc_pluto_16v2.zip ../output/dcp_pluto_archive_17v1_nyc_pluto_17v1.zip ../output/dcp_pluto_archive_17v1.1_nyc_pluto_17v1_1.zip ../output/dcp_pluto_archive_18v1_nyc_pluto_18v1.zip

include ../../shared/code/generic.make
