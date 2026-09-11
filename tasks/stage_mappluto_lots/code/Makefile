include ../../shared/code/shell_functions.make

EARLY_MAPPLUTO_RELEASES := 09v1 09v2 10v1 10v2 11v1 11v2 12v1 12v2 13v1 13v2 14v1 14v2 15v1 16v1 16v2 17v1 17v1_1
MAPPLUTO_RELEASES := 18v1_1 18v2_1 18v2 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 22v1 22v2 23v1 \
	23v1_1 23v1_2 23v2 23v3 23v3_1
PLUTO_RELEASES := 09v1 09v2 10v1 10v2 11v1 11v2 12v1 12v2 13v1 13v2 14v1 14v2 15v1 16v1 16v2 17v1 17v1_1 18v1
MAPPLUTO_DATA_RELEASES := 18v1_1 18v2_1 18v2beta 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 22v1 22v2 \
	23v1 23v1_1 23v1_2 23v2 23v3 23v3_1
PLUTO_DATA_RELEASES := 09v1 09v2 10v1 10v2 11v1 11v2 12v1 12v2 13v1 13v2 14v1 14v2 15v1 16v1 16v2 17v1 17v1_1 18v1

all: $(foreach v,$(MAPPLUTO_DATA_RELEASES),../report/dcp_mappluto_archive_$(v)_raw.txt ../output/dcp_mappluto_archive_$(v)_raw.parquet) \
	$(foreach v,$(PLUTO_DATA_RELEASES),../report/dcp_pluto_archive_$(v)_raw.txt ../output/dcp_pluto_archive_$(v)_raw.parquet) \
	../report/mappluto_raw_files.txt ../output/mappluto_raw_files.csv \
	$(foreach v,$(MAPPLUTO_DATA_RELEASES),../report/dcp_mappluto_archive_$(v).txt ../output/dcp_mappluto_archive_$(v).parquet) \
	$(foreach v,$(PLUTO_DATA_RELEASES),../report/dcp_pluto_archive_$(v).txt ../output/dcp_pluto_archive_$(v).parquet) \
	../report/mappluto_lot_files.txt ../output/mappluto_lot_files.csv

../output/mappluto_lot_files.csv ../report/mappluto_lot_files.txt: index_mappluto_lots.R \
	../../shared/code/source_pipeline_utils.R Makefile ../output/mappluto_raw_files.csv \
	$(foreach v,$(MAPPLUTO_DATA_RELEASES),../output/dcp_mappluto_archive_$(v).parquet) \
	$(foreach v,$(PLUTO_DATA_RELEASES),../output/dcp_pluto_archive_$(v).parquet) ../../shared/code/write_data_report.R | \
	../output ../report
	$(R) $<

../output/dcp_mappluto_archive_%.parquet ../report/dcp_mappluto_archive_%.txt: stage_mappluto_lots.R \
	../../shared/code/source_pipeline_utils.R Makefile ../input/source_files.csv \
	../output/dcp_mappluto_archive_%_raw.parquet ../../shared/code/write_data_report.R | ../output ../report
	$(R) $< dcp_mappluto_archive $*

../output/dcp_pluto_archive_%.parquet ../report/dcp_pluto_archive_%.txt: stage_mappluto_lots.R \
	../../shared/code/source_pipeline_utils.R Makefile ../input/source_files.csv ../output/dcp_pluto_archive_%_raw.parquet \
	../../shared/code/write_data_report.R | ../output ../report
	$(R) $< dcp_pluto_archive $*

../output/mappluto_raw_files.csv ../report/mappluto_raw_files.txt: index_mappluto_releases.R \
	../../shared/code/source_pipeline_utils.R Makefile ../input/mappluto_files.csv \
	$(foreach v,$(MAPPLUTO_DATA_RELEASES),../output/dcp_mappluto_archive_$(v)_raw.parquet) \
	$(foreach v,$(PLUTO_DATA_RELEASES),../output/dcp_pluto_archive_$(v)_raw.parquet) \
	$(foreach v,$(EARLY_MAPPLUTO_RELEASES),../input/mappluto_$(v).zip) \
	$(foreach v,$(MAPPLUTO_RELEASES),../input/nyc_mappluto_$(v)_arc_shp.zip) \
	$(foreach v,$(PLUTO_RELEASES),../input/nyc_pluto_$(v).zip) ../../shared/code/write_data_report.R | ../output ../report
	$(R) $<

../output/dcp_mappluto_archive_%_raw.parquet ../report/dcp_mappluto_archive_%_raw.txt: load_mappluto_raw.R \
	../../shared/code/source_pipeline_utils.R Makefile ../input/source_files.csv ../input/nyc_mappluto_%_arc_shp.zip \
	../../shared/code/write_data_report.R | ../output ../report
	$(R) $< dcp_mappluto_archive $*

../output/dcp_pluto_archive_%_raw.parquet ../report/dcp_pluto_archive_%_raw.txt: load_mappluto_raw.R \
	../../shared/code/source_pipeline_utils.R Makefile ../input/source_files.csv ../input/nyc_pluto_%.zip \
	../../shared/code/write_data_report.R | ../output ../report
	$(R) $< dcp_pluto_archive $*

../output/dcp_mappluto_archive_18v2beta_raw.parquet ../report/dcp_mappluto_archive_18v2beta_raw.txt: \
	load_mappluto_raw.R ../../shared/code/source_pipeline_utils.R Makefile ../input/source_files.csv \
	../input/nyc_mappluto_18v2_arc_shp.zip ../../shared/code/write_data_report.R | ../output ../report
	$(R) $< dcp_mappluto_archive 18v2beta

../input/source_files.csv: ../../fetch_mappluto_archive/code/source_files.csv | ../input
	ln -sf $< $@

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	ln -sf $< $@

../input/%.zip: ../../fetch_mappluto_archive/output/%.zip | ../input
	ln -sf $< $@

link-inputs: ../input/source_files.csv ../input/mappluto_files.csv \
	$(foreach v,$(MAPPLUTO_RELEASES),../input/nyc_mappluto_$(v)_arc_shp.zip) \
	$(foreach v,$(PLUTO_RELEASES),../input/nyc_pluto_$(v).zip) \
	$(foreach v,$(EARLY_MAPPLUTO_RELEASES),../input/mappluto_$(v).zip)

include ../../shared/code/generic.make
