include ../../shared/code/shell_functions.make

START_YEAR := 2010
END_YEAR := 2023
MIN_UNITS := 6
NEARBY_METERS := 100
REVIEW_METERS := 250
MAX_FILING_DAYS := 365
CORROBORATION_DAYS := 30

ifneq ($(filter command,$(origin START_YEAR) $(origin END_YEAR) $(origin MIN_UNITS) $(origin NEARBY_METERS) $(origin REVIEW_METERS) $(origin MAX_FILING_DAYS) $(origin CORROBORATION_DAYS)),)
$(error These fixed-name outputs use the settings recorded in this Makefile; edit those settings here so Make tracks the change)
endif

all: ../output/historical_parent_filing_link_fields.parquet ../output/historical_parent_candidate_pairs.parquet \
	../report/historical_parent_candidate_pairs.txt ../report/historical_parent_filing_link_fields.txt \
	../output/historical_polygon_adjacency_pairs.parquet ../output/historical_polygon_geometry_coverage.parquet \
	../report/historical_polygon_adjacency_pairs.txt ../report/historical_polygon_geometry_coverage.txt

../output/historical_parent_candidate_pairs.parquet: construct_historical_parent_candidate_pairs.R Makefile \
	../../shared/code/source_pipeline_utils.R ../output/historical_parent_filing_link_fields.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $< $(NEARBY_METERS) $(REVIEW_METERS) $(MAX_FILING_DAYS)

../output/historical_parent_filing_link_fields.parquet: extract_historical_parent_link_fields.R Makefile \
	../input/pair_decisions.csv ../input/mappluto_09v1.zip ../input/mappluto_09v2.zip ../input/mappluto_10v1.zip \
	../input/mappluto_10v2.zip ../input/mappluto_11v1.zip ../input/mappluto_11v2.zip ../input/mappluto_12v1.zip \
	../input/mappluto_12v2.zip ../input/mappluto_13v1.zip ../input/mappluto_13v2.zip ../input/mappluto_14v1.zip \
	../input/mappluto_14v2.zip ../input/mappluto_15v1.zip ../input/mappluto_16v1.zip ../input/mappluto_16v2.zip \
	../input/mappluto_17v1.zip ../input/mappluto_17v1_1.zip ../input/nyc_mappluto_18v1_1_arc_shp.zip \
	../input/nyc_mappluto_18v2_1_arc_shp.zip ../input/nyc_mappluto_18v2_arc_shp.zip \
	../input/nyc_mappluto_19v1_arc_shp.zip ../input/nyc_mappluto_19v2_arc_shp.zip \
	../input/nyc_mappluto_20v1_arc_shp.zip ../input/nyc_mappluto_20v2_arc_shp.zip \
	../input/nyc_mappluto_20v3_arc_shp.zip ../input/nyc_mappluto_20v4_arc_shp.zip \
	../input/nyc_mappluto_20v5_arc_shp.zip ../input/nyc_mappluto_20v6_arc_shp.zip \
	../input/nyc_mappluto_20v7_arc_shp.zip ../input/nyc_mappluto_20v8_arc_shp.zip \
	../input/nyc_mappluto_21v1_arc_shp.zip ../input/nyc_mappluto_21v3_arc_shp.zip \
	../input/nyc_mappluto_22v1_arc_shp.zip ../input/nyc_mappluto_22v2_arc_shp.zip \
	../input/nyc_mappluto_23v1_arc_shp.zip ../input/nyc_mappluto_23v1_1_arc_shp.zip \
	../input/nyc_mappluto_23v1_2_arc_shp.zip ../input/nyc_mappluto_23v2_arc_shp.zip \
	../input/nyc_mappluto_23v3_arc_shp.zip ../input/nyc_mappluto_23v3_1_arc_shp.zip ../input/nyc_pluto_09v1.zip \
	../input/nyc_pluto_09v2.zip ../input/nyc_pluto_10v1.zip ../input/nyc_pluto_10v2.zip ../input/nyc_pluto_11v1.zip \
	../input/nyc_pluto_11v2.zip ../input/nyc_pluto_12v1.zip ../input/nyc_pluto_12v2.zip ../input/nyc_pluto_13v1.zip \
	../input/nyc_pluto_13v2.zip ../input/nyc_pluto_14v1.zip ../input/nyc_pluto_14v2.zip ../input/nyc_pluto_15v1.zip \
	../input/nyc_pluto_16v1.zip ../input/nyc_pluto_16v2.zip ../input/nyc_pluto_17v1.zip ../input/nyc_pluto_17v1_1.zip \
	../input/nyc_pluto_18v1.zip ../../shared/code/source_pipeline_utils.R ../input/hdb_mappluto_site_panel.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet ../input/dob_now_new_building_initial_filings.parquet \
	../input/mappluto_files.csv ../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $< $(START_YEAR) $(END_YEAR) $(MIN_UNITS)

../report/historical_parent_candidate_pairs.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/historical_parent_candidate_pairs.parquet Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../report
	$(R) $< historical_parent_candidate_pairs

../report/historical_parent_filing_link_fields.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/historical_parent_filing_link_fields.parquet Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../report
	$(R) $< historical_parent_filing_link_fields

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
	../input/nyc_pluto_10v1.zip ../input/nyc_pluto_10v2.zip ../input/nyc_pluto_11v1.zip ../input/nyc_pluto_11v2.zip \
	../input/nyc_pluto_12v1.zip ../input/nyc_pluto_12v2.zip ../input/nyc_pluto_13v1.zip ../input/nyc_pluto_13v2.zip \
	../input/nyc_pluto_14v1.zip ../input/nyc_pluto_14v2.zip ../input/nyc_pluto_15v1.zip ../input/nyc_pluto_16v1.zip \
	../input/nyc_pluto_16v2.zip ../input/nyc_pluto_17v1.zip ../input/nyc_pluto_17v1_1.zip ../input/nyc_pluto_18v1.zip \
	../../shared/code/source_pipeline_utils.R ../output/historical_parent_filing_link_fields.parquet \
	../output/historical_parent_candidate_pairs.parquet ../input/mappluto_files.csv \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $< $(START_YEAR) $(END_YEAR) $(MAX_FILING_DAYS) $(CORROBORATION_DAYS)

../output/historical_polygon_geometry_coverage.parquet: ../output/historical_polygon_adjacency_pairs.parquet
	$(RECOVER) -W construct_historical_parent_adjacency.R all

../report/historical_polygon_adjacency_pairs.txt: report_data.R \
	../../shared/code/write_data_report.R ../output/historical_polygon_adjacency_pairs.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< historical_polygon_adjacency_pairs

../report/historical_polygon_geometry_coverage.txt: report_data.R \
	../../shared/code/write_data_report.R ../output/historical_polygon_geometry_coverage.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< historical_polygon_geometry_coverage

../input/hdb_mappluto_site_panel.parquet: ../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet \
	| ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_housing_database_project_level_raw_25q4.parquet: \
	../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/pair_decisions.csv: ../../parent_opportunities_manual/output/pair_decisions.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

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

../input/mappluto_17v1_1.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_17v1.1_mappluto_17v1_1.zip | \
	../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_18v1_1_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_18v1.1_nyc_mappluto_18v1_1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_18v2_1_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_18v2.1_nyc_mappluto_18v2_1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_18v2_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_18v2Beta_nyc_mappluto_18v2_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_19v1_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_19v1_nyc_mappluto_19v1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_19v2_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_19v2_nyc_mappluto_19v2_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v1_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v1_nyc_mappluto_20v1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v2_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v2_nyc_mappluto_20v2_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v3_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v3_nyc_mappluto_20v3_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v4_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v4_nyc_mappluto_20v4_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v5_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v5_nyc_mappluto_20v5_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v6_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v6_nyc_mappluto_20v6_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v7_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v7_nyc_mappluto_20v7_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_20v8_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_20v8_nyc_mappluto_20v8_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_21v1_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_21v1_nyc_mappluto_21v1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_21v3_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_21v3_nyc_mappluto_21v3_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_22v1_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_22v1_nyc_mappluto_22v1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_22v2_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_22v2_nyc_mappluto_22v2_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_23v1_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v1_nyc_mappluto_23v1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_23v1_1_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v1.1_nyc_mappluto_23v1_1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_23v1_2_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v1.2_nyc_mappluto_23v1_2_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_23v2_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v2_nyc_mappluto_23v2_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_23v3_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v3_nyc_mappluto_23v3_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_mappluto_23v3_1_arc_shp.zip: \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v3.1_nyc_mappluto_23v3_1_arc_shp.zip | ../input
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

../input/nyc_pluto_17v1_1.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_17v1.1_nyc_pluto_17v1_1.zip | \
	../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/nyc_pluto_18v1.zip: ../../fetch_mappluto_archive/output/dcp_pluto_archive_18v1_nyc_pluto_18v1.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

.PHONY: check-build_hdb_mappluto_site_panel

check-build_hdb_mappluto_site_panel:
	$(MAKE) -C ../../build_hdb_mappluto_site_panel/code all ../output/hdb_mappluto_site_panel.parquet

.PHONY: check-stage_dcp_housing_database

check-stage_dcp_housing_database:
	$(MAKE) -C ../../stage_dcp_housing_database/code all ../output/dcp_housing_database_project_level_raw_25q4.parquet

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet

.PHONY: check-fetch_mappluto_archive

check-fetch_mappluto_archive:
	$(MAKE) -C ../../fetch_mappluto_archive/code all ../output/mappluto_files.csv \
	../output/dcp_mappluto_archive_09v1_mappluto_09v1.zip ../output/dcp_mappluto_archive_09v2_mappluto_09v2.zip \
	../output/dcp_mappluto_archive_10v1_mappluto_10v1.zip ../output/dcp_mappluto_archive_10v2_mappluto_10v2.zip \
	../output/dcp_mappluto_archive_11v1_mappluto_11v1.zip ../output/dcp_mappluto_archive_11v2_mappluto_11v2.zip \
	../output/dcp_mappluto_archive_12v1_mappluto_12v1.zip ../output/dcp_mappluto_archive_12v2_mappluto_12v2.zip \
	../output/dcp_mappluto_archive_13v1_mappluto_13v1.zip ../output/dcp_mappluto_archive_13v2_mappluto_13v2.zip \
	../output/dcp_mappluto_archive_14v1_mappluto_14v1.zip ../output/dcp_mappluto_archive_14v2_mappluto_14v2.zip \
	../output/dcp_mappluto_archive_15v1_mappluto_15v1.zip ../output/dcp_mappluto_archive_16v1_mappluto_16v1.zip \
	../output/dcp_mappluto_archive_16v2_mappluto_16v2.zip ../output/dcp_mappluto_archive_17v1_mappluto_17v1.zip \
	../output/dcp_mappluto_archive_17v1.1_mappluto_17v1_1.zip \
	../output/dcp_mappluto_archive_18v1.1_nyc_mappluto_18v1_1_arc_shp.zip \
	../output/dcp_mappluto_archive_18v2.1_nyc_mappluto_18v2_1_arc_shp.zip \
	../output/dcp_mappluto_archive_18v2Beta_nyc_mappluto_18v2_arc_shp.zip \
	../output/dcp_mappluto_archive_19v1_nyc_mappluto_19v1_arc_shp.zip \
	../output/dcp_mappluto_archive_19v2_nyc_mappluto_19v2_arc_shp.zip \
	../output/dcp_mappluto_archive_20v1_nyc_mappluto_20v1_arc_shp.zip \
	../output/dcp_mappluto_archive_20v2_nyc_mappluto_20v2_arc_shp.zip \
	../output/dcp_mappluto_archive_20v3_nyc_mappluto_20v3_arc_shp.zip \
	../output/dcp_mappluto_archive_20v4_nyc_mappluto_20v4_arc_shp.zip \
	../output/dcp_mappluto_archive_20v5_nyc_mappluto_20v5_arc_shp.zip \
	../output/dcp_mappluto_archive_20v6_nyc_mappluto_20v6_arc_shp.zip \
	../output/dcp_mappluto_archive_20v7_nyc_mappluto_20v7_arc_shp.zip \
	../output/dcp_mappluto_archive_20v8_nyc_mappluto_20v8_arc_shp.zip \
	../output/dcp_mappluto_archive_21v1_nyc_mappluto_21v1_arc_shp.zip \
	../output/dcp_mappluto_archive_21v3_nyc_mappluto_21v3_arc_shp.zip \
	../output/dcp_mappluto_archive_22v1_nyc_mappluto_22v1_arc_shp.zip \
	../output/dcp_mappluto_archive_22v2_nyc_mappluto_22v2_arc_shp.zip \
	../output/dcp_mappluto_archive_23v1_nyc_mappluto_23v1_arc_shp.zip \
	../output/dcp_mappluto_archive_23v1.1_nyc_mappluto_23v1_1_arc_shp.zip \
	../output/dcp_mappluto_archive_23v1.2_nyc_mappluto_23v1_2_arc_shp.zip \
	../output/dcp_mappluto_archive_23v2_nyc_mappluto_23v2_arc_shp.zip \
	../output/dcp_mappluto_archive_23v3_nyc_mappluto_23v3_arc_shp.zip \
	../output/dcp_mappluto_archive_23v3.1_nyc_mappluto_23v3_1_arc_shp.zip \
	../output/dcp_pluto_archive_09v1_nyc_pluto_09v1.zip ../output/dcp_pluto_archive_09v2_nyc_pluto_09v2.zip \
	../output/dcp_pluto_archive_10v1_nyc_pluto_10v1.zip ../output/dcp_pluto_archive_10v2_nyc_pluto_10v2.zip \
	../output/dcp_pluto_archive_11v1_nyc_pluto_11v1.zip ../output/dcp_pluto_archive_11v2_nyc_pluto_11v2.zip \
	../output/dcp_pluto_archive_12v1_nyc_pluto_12v1.zip ../output/dcp_pluto_archive_12v2_nyc_pluto_12v2.zip \
	../output/dcp_pluto_archive_13v1_nyc_pluto_13v1.zip ../output/dcp_pluto_archive_13v2_nyc_pluto_13v2.zip \
	../output/dcp_pluto_archive_14v1_nyc_pluto_14v1.zip ../output/dcp_pluto_archive_14v2_nyc_pluto_14v2.zip \
	../output/dcp_pluto_archive_15v1_nyc_pluto_15v1.zip ../output/dcp_pluto_archive_16v1_nyc_pluto_16v1.zip \
	../output/dcp_pluto_archive_16v2_nyc_pluto_16v2.zip ../output/dcp_pluto_archive_17v1_nyc_pluto_17v1.zip \
	../output/dcp_pluto_archive_17v1.1_nyc_pluto_17v1_1.zip ../output/dcp_pluto_archive_18v1_nyc_pluto_18v1.zip

../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet: check-build_hdb_mappluto_site_panel ;

../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_25q4.parquet: check-stage_dcp_housing_database ;

../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet: check-stage_dob_now_new_building_filings ;

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

link-inputs: ../input/hdb_mappluto_site_panel.parquet ../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet ../input/mappluto_files.csv ../input/pair_decisions.csv \
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
	../input/nyc_pluto_10v1.zip ../input/nyc_pluto_10v2.zip ../input/nyc_pluto_11v1.zip ../input/nyc_pluto_11v2.zip \
	../input/nyc_pluto_12v1.zip ../input/nyc_pluto_12v2.zip ../input/nyc_pluto_13v1.zip ../input/nyc_pluto_13v2.zip \
	../input/nyc_pluto_14v1.zip ../input/nyc_pluto_14v2.zip ../input/nyc_pluto_15v1.zip ../input/nyc_pluto_16v1.zip \
	../input/nyc_pluto_16v2.zip ../input/nyc_pluto_17v1.zip ../input/nyc_pluto_17v1_1.zip ../input/nyc_pluto_18v1.zip

include ../../shared/code/generic.make
