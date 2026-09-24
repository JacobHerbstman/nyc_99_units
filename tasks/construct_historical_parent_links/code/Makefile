include ../../shared/code/shell_functions.make

# PLUTO CSV releases through 18v1 and MapPLUTO shapefiles afterwards supply
# owners and former lots; the MapPLUTO shapefiles, including the early archive
# releases, supply lot geometry.
PLUTO_ZIPS := $(foreach v,09v1 09v2 10v1 10v2 11v1 11v2 12v1 12v2 13v1 13v2 14v1 14v2 15v1 16v1 16v2 17v1 17v1_1 18v1, \
	../input/nyc_pluto_$(v).zip)
MAPPLUTO_ZIPS := $(foreach v,18v1_1 18v2_1 18v2 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 22v1 22v2 \
	23v1 23v1_1 23v1_2 23v2 23v3 23v3_1,../input/nyc_mappluto_$(v)_arc_shp.zip)
EARLY_MAPPLUTO_ZIPS := $(foreach v,09v1 09v2 10v1 10v2 11v1 11v2 12v1 12v2 13v1 13v2 14v1 14v2 15v1 16v1 16v2 17v1 \
	17v1_1,../input/mappluto_$(v).zip)

all: ../output/historical_parent_filing_link_fields.parquet ../output/historical_parent_pairs.parquet

include ../../shared/code/generic.make

../output/historical_parent_filing_link_fields.parquet: extract_historical_parent_link_fields.R \
	../input/historical_hdb_mappluto_site_panel.parquet ../input/dcp_housing_database_project_level_raw_23q4.parquet \
	../input/pair_decisions.csv ../input/mappluto_files.csv $(PLUTO_ZIPS) $(MAPPLUTO_ZIPS) Makefile | $(OOPR)
	$(R) $<

../output/historical_parent_pairs.parquet: construct_historical_parent_pairs.R \
	../output/historical_parent_filing_link_fields.parquet ../input/mappluto_files.csv $(MAPPLUTO_ZIPS) \
	$(EARLY_MAPPLUTO_ZIPS) Makefile | $(OOPR)
	$(R) $<

../input/historical_hdb_mappluto_site_panel.parquet: \
	../../build_hdb_mappluto_site_panel/output/historical_hdb_mappluto_site_panel.parquet | ../input
	ln -sf $< $@

../input/dcp_housing_database_project_level_raw_23q4.parquet: \
	../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_23q4.parquet | ../input
	ln -sf $< $@

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	ln -sf $< $@

../input/pair_decisions.csv: ../../parent_opportunities_manual/output/pair_decisions.csv | ../input
	ln -sf $< $@

../input/%.zip: ../../fetch_mappluto_archive/output/%.zip | ../input
	ln -sf $< $@
