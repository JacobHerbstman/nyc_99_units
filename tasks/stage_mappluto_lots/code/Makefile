include ../../shared/code/shell_functions.make

MAPPLUTO_RELEASES := 18v1_1 18v2_1 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 22v1 22v2 23v1 \
	23v1_1 23v1_2 23v2 23v3 23v3_1
PLUTO_RELEASES := 09v1 09v2 10v1 10v2 11v1 11v2 12v1 12v2 13v1 13v2 14v1 14v2 15v1 16v1 16v2 17v1 17v1_1 18v1

all: $(foreach v,$(MAPPLUTO_RELEASES) 18v2beta,../output/dcp_mappluto_archive_$(v).parquet) \
	$(foreach v,$(PLUTO_RELEASES),../output/dcp_pluto_archive_$(v).parquet)

include ../../shared/code/generic.make

../output/dcp_mappluto_archive_%.parquet: stage_mappluto_lots.R ../input/source_files.csv \
	../input/nyc_mappluto_%_arc_shp.zip Makefile | $(OOPR)
	$(R) $< dcp_mappluto_archive $*

# The 18v2 beta release is distributed under the 18v2 file name.
../output/dcp_mappluto_archive_18v2beta.parquet: stage_mappluto_lots.R ../input/source_files.csv \
	../input/nyc_mappluto_18v2_arc_shp.zip Makefile | $(OOPR)
	$(R) $< dcp_mappluto_archive 18v2beta

../output/dcp_pluto_archive_%.parquet: stage_mappluto_lots.R ../input/source_files.csv ../input/nyc_pluto_%.zip \
	Makefile | $(OOPR)
	$(R) $< dcp_pluto_archive $*

../input/source_files.csv: ../../fetch_mappluto_archive/code/source_files.csv | ../input
	ln -sf $< $@

../input/%.zip: ../../fetch_mappluto_archive/output/%.zip | ../input
	ln -sf $< $@
