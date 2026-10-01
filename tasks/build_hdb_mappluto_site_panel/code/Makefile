include ../../shared/code/shell_functions.make

PARCEL_RELEASES := $(foreach v,18v1_1 18v2_1 18v2beta 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 \
	22v1 22v2 23v1 23v1_1 23v1_2 23v2 23v3 23v3_1,../input/dcp_mappluto_archive_$(v).parquet) \
	$(foreach v,09v1 09v2 10v1 10v2 11v1 11v2 12v1 12v2 13v1 13v2 14v1 14v2 15v1 16v1 16v2 17v1 17v1_1 18v1, \
	../input/dcp_pluto_archive_$(v).parquet)

all: ../output/mappluto_release_calendar.csv ../output/mappluto_appbbl_crosswalk.csv \
	../output/historical_hdb_mappluto_site_panel.parquet ../output/hdb_mappluto_site_panel.parquet

include ../../shared/code/generic.make

../output/mappluto_release_calendar.csv: define_mappluto_release_calendar.R mappluto_release_calendar_manual.csv \
	Makefile | $(OOPR)
	$(R) $<

../output/mappluto_appbbl_crosswalk.csv: build_mappluto_appbbl_crosswalk.R ../input/nyc_pluto_25v4_csv.zip \
	Makefile | $(OOPR)
	$(R) $<

../output/historical_hdb_mappluto_site_panel.parquet: build_hdb_mappluto_site_panel.R \
	../input/dcp_housing_database_project_level_23q4.parquet ../output/mappluto_release_calendar.csv \
	../output/mappluto_appbbl_crosswalk.csv $(PARCEL_RELEASES) Makefile | $(OOPR)
	$(R) $< 23Q4

../output/hdb_mappluto_site_panel.parquet: build_hdb_mappluto_site_panel.R \
	../input/dcp_housing_database_project_level_25q4.parquet ../output/mappluto_release_calendar.csv \
	../output/mappluto_appbbl_crosswalk.csv $(PARCEL_RELEASES) Makefile | $(OOPR)
	$(R) $< 25Q4

../input/dcp_housing_database_project_level_%.parquet: \
	../../stage_dcp_housing_database/output/dcp_housing_database_project_level_%.parquet | ../input
	ln -sf $< $@

../input/nyc_pluto_25v4_csv.zip: ../../fetch_mappluto_archive/output/nyc_pluto_25v4_csv.zip | ../input
	ln -sf $< $@

../input/dcp_%.parquet: ../../stage_mappluto_lots/output/dcp_%.parquet | ../input
	ln -sf $< $@
