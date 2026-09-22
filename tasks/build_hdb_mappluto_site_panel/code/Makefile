include ../../shared/code/shell_functions.make

MAPPLUTO_DATA_RELEASES:= 18v1_1 18v2_1 18v2beta 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 \
	22v1 22v2 23v1 23v1_1 23v1_2 23v2 23v3 23v3_1
PLUTO_DATA_RELEASES:= 09v1 09v2 10v1 10v2 11v1 11v2 12v1 12v2 13v1 13v2 14v1 14v2 15v1 16v1 16v2 17v1 17v1_1 \
	18v1

all: ../output/mappluto_release_calendar.csv ../output/mappluto_appbbl_crosswalk.csv \
	../output/hdb_mappluto_site_panel.parquet ../output/historical_hdb_mappluto_site_panel.parquet

include ../../shared/code/generic.make

../output/hdb_mappluto_site_panel.parquet: build_hdb_mappluto_site_panel.R \
	../../shared/code/source_pipeline_utils.R ../input/dcp_housing_database_project_level_25q4.parquet \
	../input/mappluto_lot_files.csv ../output/mappluto_release_calendar.csv ../output/mappluto_appbbl_crosswalk.csv \
	Makefile $(foreach v,$(MAPPLUTO_DATA_RELEASES),../input/dcp_mappluto_archive_$(v).parquet) \
	$(foreach v,$(PLUTO_DATA_RELEASES),../input/dcp_pluto_archive_$(v).parquet) \
	../../shared/code/write_data_report.R | $(OOPR)
	$(R) $< 2010-01-01 2025-12-31 25Q4

../output/historical_hdb_mappluto_site_panel.parquet: build_hdb_mappluto_site_panel.R \
	../../shared/code/source_pipeline_utils.R ../input/dcp_housing_database_project_level_23q4.parquet \
	../input/mappluto_lot_files.csv ../output/mappluto_release_calendar.csv ../output/mappluto_appbbl_crosswalk.csv \
	Makefile $(foreach v,$(MAPPLUTO_DATA_RELEASES),../input/dcp_mappluto_archive_$(v).parquet) \
	$(foreach v,$(PLUTO_DATA_RELEASES),../input/dcp_pluto_archive_$(v).parquet) \
	../../shared/code/write_data_report.R | $(OOPR)
	$(R) $< 2010-01-01 2023-12-31 23Q4

../output/mappluto_release_calendar.csv: define_mappluto_release_calendar.R \
	../../shared/code/source_pipeline_utils.R mappluto_release_calendar_manual.csv ../input/mappluto_lot_files.csv \
	Makefile ../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../output/mappluto_appbbl_crosswalk.csv: build_mappluto_appbbl_crosswalk.R \
	../../shared/code/source_pipeline_utils.R ../input/mappluto_files.csv Makefile ../input/nyc_pluto_25v4_csv.zip \
	../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../input/dcp_housing_database_project_level_25q4.parquet: \
	../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet | ../input
	ln -sf $< $@

../input/mappluto_lot_files.csv: ../../stage_mappluto_lots/output/mappluto_lot_files.csv | ../input
	ln -sf $< $@

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	ln -sf $< $@

../input/%.zip: ../../fetch_mappluto_archive/output/%.zip | ../input
	ln -sf $< $@

../input/dcp_%.parquet: ../../stage_mappluto_lots/output/dcp_%.parquet | ../input
	ln -sf $< $@

../input/dcp_housing_database_project_level_23q4.parquet: \
	../../stage_dcp_housing_database/output/dcp_housing_database_project_level_23q4.parquet | ../input
	ln -sf $< $@
