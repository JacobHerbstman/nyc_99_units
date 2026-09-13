include ../../shared/code/shell_functions.make

EARLY_MAPPLUTO_RELEASES:= 09v1 09v2 10v1 10v2 11v1 11v2 12v1 12v2 13v1 13v2 14v1 14v2 15v1 16v1 16v2 17v1 \
	17v1_1
MAPPLUTO_RELEASES:= 18v1_1 18v2_1 18v2 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 22v1 22v2 \
	23v1 23v1_1 23v1_2 23v2 23v3 23v3_1
PLUTO_RELEASES:= 09v1 09v2 10v1 10v2 11v1 11v2 12v1 12v2 13v1 13v2 14v1 14v2 15v1 16v1 16v2 17v1 17v1_1 18v1

all: ../output/historical_parent_filing_link_fields.parquet ../output/historical_parent_candidate_pairs.parquet \
	../output/historical_polygon_adjacency_pairs.parquet ../output/historical_polygon_geometry_coverage.parquet

include ../../shared/code/generic.make

../output/historical_parent_candidate_pairs.parquet: construct_historical_parent_candidate_pairs.R Makefile \
	../../shared/code/source_pipeline_utils.R ../output/historical_parent_filing_link_fields.parquet \
	../../shared/code/write_data_report.R | $(OOPR)
	$(R) $< 100 250 365

../output/historical_parent_filing_link_fields.parquet: extract_historical_parent_link_fields.R Makefile \
	../input/pair_decisions.csv $(foreach v,$(EARLY_MAPPLUTO_RELEASES),../input/mappluto_$(v).zip) \
	$(foreach v,$(MAPPLUTO_RELEASES),../input/nyc_mappluto_$(v)_arc_shp.zip) \
	$(foreach v,$(PLUTO_RELEASES),../input/nyc_pluto_$(v).zip) ../../shared/code/source_pipeline_utils.R \
	../input/hdb_mappluto_site_panel.parquet ../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet ../input/mappluto_files.csv \
	../../shared/code/write_data_report.R | $(OOPR)
	$(R) $< 2010 2023 6

../output/historical_polygon_geometry_coverage.parquet ../output/historical_polygon_adjacency_pairs.parquet: \
	construct_historical_parent_adjacency.R Makefile \
	$(foreach v,$(EARLY_MAPPLUTO_RELEASES),../input/mappluto_$(v).zip) \
	$(foreach v,$(MAPPLUTO_RELEASES),../input/nyc_mappluto_$(v)_arc_shp.zip) \
	$(foreach v,$(PLUTO_RELEASES),../input/nyc_pluto_$(v).zip) ../../shared/code/source_pipeline_utils.R \
	../output/historical_parent_filing_link_fields.parquet ../output/historical_parent_candidate_pairs.parquet \
	../input/mappluto_files.csv ../../shared/code/write_data_report.R | $(OOPR)
	$(R) $< 2010 2023 365 30

../input/hdb_mappluto_site_panel.parquet: \
	../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | ../input
	ln -sf $< $@

../input/dcp_housing_database_project_level_raw_25q4.parquet: \
	../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_25q4.parquet | ../input
	ln -sf $< $@

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	ln -sf $< $@

../input/pair_decisions.csv: ../../parent_opportunities_manual/output/pair_decisions.csv | ../input
	ln -sf $< $@

../input/%.zip: ../../fetch_mappluto_archive/output/%.zip | ../input
	ln -sf $< $@
