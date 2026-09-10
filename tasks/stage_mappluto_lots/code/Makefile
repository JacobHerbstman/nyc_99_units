include ../../shared/code/shell_functions.make

all: ../output/mappluto_lot_files.csv ../report/dcp_mappluto_archive_18v1_1.txt \
	../report/dcp_mappluto_archive_18v2_1.txt ../report/dcp_mappluto_archive_18v2beta.txt \
	../report/dcp_mappluto_archive_19v1.txt ../report/dcp_mappluto_archive_19v2.txt \
	../report/dcp_mappluto_archive_20v1.txt ../report/dcp_mappluto_archive_20v2.txt \
	../report/dcp_mappluto_archive_20v3.txt ../report/dcp_mappluto_archive_20v4.txt \
	../report/dcp_mappluto_archive_20v5.txt ../report/dcp_mappluto_archive_20v6.txt \
	../report/dcp_mappluto_archive_20v7.txt ../report/dcp_mappluto_archive_20v8.txt \
	../report/dcp_mappluto_archive_21v1.txt ../report/dcp_mappluto_archive_21v3.txt \
	../report/dcp_mappluto_archive_22v1.txt ../report/dcp_mappluto_archive_22v2.txt \
	../report/dcp_mappluto_archive_23v1.txt ../report/dcp_mappluto_archive_23v1_1.txt \
	../report/dcp_mappluto_archive_23v1_2.txt ../report/dcp_mappluto_archive_23v2.txt \
	../report/dcp_mappluto_archive_23v3.txt ../report/dcp_mappluto_archive_23v3_1.txt \
	../report/dcp_pluto_archive_09v1.txt ../report/dcp_pluto_archive_09v2.txt ../report/dcp_pluto_archive_10v1.txt \
	../report/dcp_pluto_archive_10v2.txt ../report/dcp_pluto_archive_11v1.txt ../report/dcp_pluto_archive_11v2.txt \
	../report/dcp_pluto_archive_12v1.txt ../report/dcp_pluto_archive_12v2.txt ../report/dcp_pluto_archive_13v1.txt \
	../report/dcp_pluto_archive_13v2.txt ../report/dcp_pluto_archive_14v1.txt ../report/dcp_pluto_archive_14v2.txt \
	../report/dcp_pluto_archive_15v1.txt ../report/dcp_pluto_archive_16v1.txt ../report/dcp_pluto_archive_16v2.txt \
	../report/dcp_pluto_archive_17v1.txt ../report/dcp_pluto_archive_17v1_1.txt ../report/dcp_pluto_archive_18v1.txt \
	../report/mappluto_lot_files.txt ../output/mappluto_raw_files.csv ../report/dcp_mappluto_archive_18v1_1_raw.txt \
	../report/dcp_mappluto_archive_18v2_1_raw.txt ../report/dcp_mappluto_archive_18v2beta_raw.txt \
	../report/dcp_mappluto_archive_19v1_raw.txt ../report/dcp_mappluto_archive_19v2_raw.txt \
	../report/dcp_mappluto_archive_20v1_raw.txt ../report/dcp_mappluto_archive_20v2_raw.txt \
	../report/dcp_mappluto_archive_20v3_raw.txt ../report/dcp_mappluto_archive_20v4_raw.txt \
	../report/dcp_mappluto_archive_20v5_raw.txt ../report/dcp_mappluto_archive_20v6_raw.txt \
	../report/dcp_mappluto_archive_20v7_raw.txt ../report/dcp_mappluto_archive_20v8_raw.txt \
	../report/dcp_mappluto_archive_21v1_raw.txt ../report/dcp_mappluto_archive_21v3_raw.txt \
	../report/dcp_mappluto_archive_22v1_raw.txt ../report/dcp_mappluto_archive_22v2_raw.txt \
	../report/dcp_mappluto_archive_23v1_1_raw.txt ../report/dcp_mappluto_archive_23v1_2_raw.txt \
	../report/dcp_mappluto_archive_23v1_raw.txt ../report/dcp_mappluto_archive_23v2_raw.txt \
	../report/dcp_mappluto_archive_23v3_1_raw.txt ../report/dcp_mappluto_archive_23v3_raw.txt \
	../report/dcp_pluto_archive_09v1_raw.txt ../report/dcp_pluto_archive_09v2_raw.txt \
	../report/dcp_pluto_archive_10v1_raw.txt ../report/dcp_pluto_archive_10v2_raw.txt \
	../report/dcp_pluto_archive_11v1_raw.txt ../report/dcp_pluto_archive_11v2_raw.txt \
	../report/dcp_pluto_archive_12v1_raw.txt ../report/dcp_pluto_archive_12v2_raw.txt \
	../report/dcp_pluto_archive_13v1_raw.txt ../report/dcp_pluto_archive_13v2_raw.txt \
	../report/dcp_pluto_archive_14v1_raw.txt ../report/dcp_pluto_archive_14v2_raw.txt \
	../report/dcp_pluto_archive_15v1_raw.txt ../report/dcp_pluto_archive_16v1_raw.txt \
	../report/dcp_pluto_archive_16v2_raw.txt ../report/dcp_pluto_archive_17v1_1_raw.txt \
	../report/dcp_pluto_archive_17v1_raw.txt ../report/dcp_pluto_archive_18v1_raw.txt ../report/mappluto_raw_files.txt

../output/mappluto_lot_files.csv: index_mappluto_lots.R ../../shared/code/source_pipeline_utils.R Makefile \
	../output/mappluto_raw_files.csv ../output/dcp_mappluto_archive_18v1_1.parquet \
	../output/dcp_mappluto_archive_18v2_1.parquet ../output/dcp_mappluto_archive_18v2beta.parquet \
	../output/dcp_mappluto_archive_19v1.parquet ../output/dcp_mappluto_archive_19v2.parquet \
	../output/dcp_mappluto_archive_20v1.parquet ../output/dcp_mappluto_archive_20v2.parquet \
	../output/dcp_mappluto_archive_20v3.parquet ../output/dcp_mappluto_archive_20v4.parquet \
	../output/dcp_mappluto_archive_20v5.parquet ../output/dcp_mappluto_archive_20v6.parquet \
	../output/dcp_mappluto_archive_20v7.parquet ../output/dcp_mappluto_archive_20v8.parquet \
	../output/dcp_mappluto_archive_21v1.parquet ../output/dcp_mappluto_archive_21v3.parquet \
	../output/dcp_mappluto_archive_22v1.parquet ../output/dcp_mappluto_archive_22v2.parquet \
	../output/dcp_mappluto_archive_23v1.parquet ../output/dcp_mappluto_archive_23v1_1.parquet \
	../output/dcp_mappluto_archive_23v1_2.parquet ../output/dcp_mappluto_archive_23v2.parquet \
	../output/dcp_mappluto_archive_23v3.parquet ../output/dcp_mappluto_archive_23v3_1.parquet \
	../output/dcp_pluto_archive_09v1.parquet ../output/dcp_pluto_archive_09v2.parquet \
	../output/dcp_pluto_archive_10v1.parquet ../output/dcp_pluto_archive_10v2.parquet \
	../output/dcp_pluto_archive_11v1.parquet ../output/dcp_pluto_archive_11v2.parquet \
	../output/dcp_pluto_archive_12v1.parquet ../output/dcp_pluto_archive_12v2.parquet \
	../output/dcp_pluto_archive_13v1.parquet ../output/dcp_pluto_archive_13v2.parquet \
	../output/dcp_pluto_archive_14v1.parquet ../output/dcp_pluto_archive_14v2.parquet \
	../output/dcp_pluto_archive_15v1.parquet ../output/dcp_pluto_archive_16v1.parquet \
	../output/dcp_pluto_archive_16v2.parquet ../output/dcp_pluto_archive_17v1.parquet \
	../output/dcp_pluto_archive_17v1_1.parquet ../output/dcp_pluto_archive_18v1.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<

../report/dcp_mappluto_archive_18v1_1.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/dcp_mappluto_archive_18v1_1.parquet Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../report
	$(R) $< dcp_mappluto_archive_18v1_1

../report/mappluto_lot_files.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/mappluto_lot_files.csv Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../report
	$(R) $< mappluto_lot_files

../output/dcp_mappluto_archive_%.parquet: stage_mappluto_lots.R ../../shared/code/source_pipeline_utils.R Makefile \
	../input/source_files.csv ../output/dcp_mappluto_archive_%_raw.parquet ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../output
	$(R) stage_mappluto_lots.R dcp_mappluto_archive $*

../output/dcp_pluto_archive_%.parquet: stage_mappluto_lots.R ../../shared/code/source_pipeline_utils.R Makefile \
	../input/source_files.csv ../output/dcp_pluto_archive_%_raw.parquet ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../output
	$(R) stage_mappluto_lots.R dcp_pluto_archive $*

../report/dcp_%.txt: report_data.R ../../shared/code/write_data_report.R ../output/dcp_%.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) report_data.R dcp_$*

../output/mappluto_raw_files.csv: index_mappluto_releases.R ../../shared/code/source_pipeline_utils.R Makefile \
	../input/mappluto_files.csv ../output/dcp_mappluto_archive_18v1_1_raw.parquet \
	../output/dcp_mappluto_archive_18v2_1_raw.parquet ../output/dcp_mappluto_archive_18v2beta_raw.parquet \
	../output/dcp_mappluto_archive_19v1_raw.parquet ../output/dcp_mappluto_archive_19v2_raw.parquet \
	../output/dcp_mappluto_archive_20v1_raw.parquet ../output/dcp_mappluto_archive_20v2_raw.parquet \
	../output/dcp_mappluto_archive_20v3_raw.parquet ../output/dcp_mappluto_archive_20v4_raw.parquet \
	../output/dcp_mappluto_archive_20v5_raw.parquet ../output/dcp_mappluto_archive_20v6_raw.parquet \
	../output/dcp_mappluto_archive_20v7_raw.parquet ../output/dcp_mappluto_archive_20v8_raw.parquet \
	../output/dcp_mappluto_archive_21v1_raw.parquet ../output/dcp_mappluto_archive_21v3_raw.parquet \
	../output/dcp_mappluto_archive_22v1_raw.parquet ../output/dcp_mappluto_archive_22v2_raw.parquet \
	../output/dcp_mappluto_archive_23v1_raw.parquet ../output/dcp_mappluto_archive_23v1_1_raw.parquet \
	../output/dcp_mappluto_archive_23v1_2_raw.parquet ../output/dcp_mappluto_archive_23v2_raw.parquet \
	../output/dcp_mappluto_archive_23v3_raw.parquet ../output/dcp_mappluto_archive_23v3_1_raw.parquet \
	../output/dcp_pluto_archive_09v1_raw.parquet ../output/dcp_pluto_archive_09v2_raw.parquet \
	../output/dcp_pluto_archive_10v1_raw.parquet ../output/dcp_pluto_archive_10v2_raw.parquet \
	../output/dcp_pluto_archive_11v1_raw.parquet ../output/dcp_pluto_archive_11v2_raw.parquet \
	../output/dcp_pluto_archive_12v1_raw.parquet ../output/dcp_pluto_archive_12v2_raw.parquet \
	../output/dcp_pluto_archive_13v1_raw.parquet ../output/dcp_pluto_archive_13v2_raw.parquet \
	../output/dcp_pluto_archive_14v1_raw.parquet ../output/dcp_pluto_archive_14v2_raw.parquet \
	../output/dcp_pluto_archive_15v1_raw.parquet ../output/dcp_pluto_archive_16v1_raw.parquet \
	../output/dcp_pluto_archive_16v2_raw.parquet ../output/dcp_pluto_archive_17v1_raw.parquet \
	../output/dcp_pluto_archive_17v1_1_raw.parquet ../output/dcp_pluto_archive_18v1_raw.parquet \
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
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<

../report/dcp_mappluto_archive_18v1_1_raw.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/dcp_mappluto_archive_18v1_1_raw.parquet Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../report
	$(R) $< dcp_mappluto_archive_18v1_1_raw

../report/mappluto_raw_files.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/mappluto_raw_files.csv Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../report
	$(R) $< mappluto_raw_files

../output/dcp_mappluto_archive_%_raw.parquet: load_mappluto_raw.R ../../shared/code/source_pipeline_utils.R Makefile \
	../input/source_files.csv ../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) load_mappluto_raw.R dcp_mappluto_archive $*

../output/dcp_pluto_archive_%_raw.parquet: load_mappluto_raw.R ../../shared/code/source_pipeline_utils.R Makefile \
	../input/source_files.csv ../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) load_mappluto_raw.R dcp_pluto_archive $*

../output/dcp_mappluto_archive_18v1_1_raw.parquet: ../input/nyc_mappluto_18v1_1_arc_shp.zip

../output/dcp_mappluto_archive_18v2_1_raw.parquet: ../input/nyc_mappluto_18v2_1_arc_shp.zip

../output/dcp_mappluto_archive_18v2beta_raw.parquet: ../input/nyc_mappluto_18v2_arc_shp.zip

../output/dcp_mappluto_archive_19v1_raw.parquet: ../input/nyc_mappluto_19v1_arc_shp.zip

../output/dcp_mappluto_archive_19v2_raw.parquet: ../input/nyc_mappluto_19v2_arc_shp.zip

../output/dcp_mappluto_archive_20v1_raw.parquet: ../input/nyc_mappluto_20v1_arc_shp.zip

../output/dcp_mappluto_archive_20v2_raw.parquet: ../input/nyc_mappluto_20v2_arc_shp.zip

../output/dcp_mappluto_archive_20v3_raw.parquet: ../input/nyc_mappluto_20v3_arc_shp.zip

../output/dcp_mappluto_archive_20v4_raw.parquet: ../input/nyc_mappluto_20v4_arc_shp.zip

../output/dcp_mappluto_archive_20v5_raw.parquet: ../input/nyc_mappluto_20v5_arc_shp.zip

../output/dcp_mappluto_archive_20v6_raw.parquet: ../input/nyc_mappluto_20v6_arc_shp.zip

../output/dcp_mappluto_archive_20v7_raw.parquet: ../input/nyc_mappluto_20v7_arc_shp.zip

../output/dcp_mappluto_archive_20v8_raw.parquet: ../input/nyc_mappluto_20v8_arc_shp.zip

../output/dcp_mappluto_archive_21v1_raw.parquet: ../input/nyc_mappluto_21v1_arc_shp.zip

../output/dcp_mappluto_archive_21v3_raw.parquet: ../input/nyc_mappluto_21v3_arc_shp.zip

../output/dcp_mappluto_archive_22v1_raw.parquet: ../input/nyc_mappluto_22v1_arc_shp.zip

../output/dcp_mappluto_archive_22v2_raw.parquet: ../input/nyc_mappluto_22v2_arc_shp.zip

../output/dcp_mappluto_archive_23v1_raw.parquet: ../input/nyc_mappluto_23v1_arc_shp.zip

../output/dcp_mappluto_archive_23v1_1_raw.parquet: ../input/nyc_mappluto_23v1_1_arc_shp.zip

../output/dcp_mappluto_archive_23v1_2_raw.parquet: ../input/nyc_mappluto_23v1_2_arc_shp.zip

../output/dcp_mappluto_archive_23v2_raw.parquet: ../input/nyc_mappluto_23v2_arc_shp.zip

../output/dcp_mappluto_archive_23v3_raw.parquet: ../input/nyc_mappluto_23v3_arc_shp.zip

../output/dcp_mappluto_archive_23v3_1_raw.parquet: ../input/nyc_mappluto_23v3_1_arc_shp.zip

../output/dcp_pluto_archive_09v1_raw.parquet: ../input/nyc_pluto_09v1.zip

../output/dcp_pluto_archive_09v2_raw.parquet: ../input/nyc_pluto_09v2.zip

../output/dcp_pluto_archive_10v1_raw.parquet: ../input/nyc_pluto_10v1.zip

../output/dcp_pluto_archive_10v2_raw.parquet: ../input/nyc_pluto_10v2.zip

../output/dcp_pluto_archive_11v1_raw.parquet: ../input/nyc_pluto_11v1.zip

../output/dcp_pluto_archive_11v2_raw.parquet: ../input/nyc_pluto_11v2.zip

../output/dcp_pluto_archive_12v1_raw.parquet: ../input/nyc_pluto_12v1.zip

../output/dcp_pluto_archive_12v2_raw.parquet: ../input/nyc_pluto_12v2.zip

../output/dcp_pluto_archive_13v1_raw.parquet: ../input/nyc_pluto_13v1.zip

../output/dcp_pluto_archive_13v2_raw.parquet: ../input/nyc_pluto_13v2.zip

../output/dcp_pluto_archive_14v1_raw.parquet: ../input/nyc_pluto_14v1.zip

../output/dcp_pluto_archive_14v2_raw.parquet: ../input/nyc_pluto_14v2.zip

../output/dcp_pluto_archive_15v1_raw.parquet: ../input/nyc_pluto_15v1.zip

../output/dcp_pluto_archive_16v1_raw.parquet: ../input/nyc_pluto_16v1.zip

../output/dcp_pluto_archive_16v2_raw.parquet: ../input/nyc_pluto_16v2.zip

../output/dcp_pluto_archive_17v1_raw.parquet: ../input/nyc_pluto_17v1.zip

../output/dcp_pluto_archive_17v1_1_raw.parquet: ../input/nyc_pluto_17v1_1.zip

../output/dcp_pluto_archive_18v1_raw.parquet: ../input/nyc_pluto_18v1.zip

../report/dcp_%_raw.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/dcp_%_raw.parquet Makefile ../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | \
	../report
	$(R) report_data.R dcp_$*_raw

../input/source_files.csv: ../../fetch_mappluto_archive/code/source_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
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

.PHONY: check-fetch_mappluto_archive

check-fetch_mappluto_archive:
	$(MAKE) -C ../../fetch_mappluto_archive/code all ../output/mappluto_files.csv \
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
	../output/dcp_pluto_archive_17v1.1_nyc_pluto_17v1_1.zip ../output/dcp_pluto_archive_18v1_nyc_pluto_18v1.zip \
	../output/dcp_mappluto_archive_09v1_mappluto_09v1.zip ../output/dcp_mappluto_archive_09v2_mappluto_09v2.zip \
	../output/dcp_mappluto_archive_10v1_mappluto_10v1.zip ../output/dcp_mappluto_archive_10v2_mappluto_10v2.zip \
	../output/dcp_mappluto_archive_11v1_mappluto_11v1.zip ../output/dcp_mappluto_archive_11v2_mappluto_11v2.zip \
	../output/dcp_mappluto_archive_12v1_mappluto_12v1.zip ../output/dcp_mappluto_archive_12v2_mappluto_12v2.zip \
	../output/dcp_mappluto_archive_13v1_mappluto_13v1.zip ../output/dcp_mappluto_archive_13v2_mappluto_13v2.zip \
	../output/dcp_mappluto_archive_14v1_mappluto_14v1.zip ../output/dcp_mappluto_archive_14v2_mappluto_14v2.zip \
	../output/dcp_mappluto_archive_15v1_mappluto_15v1.zip ../output/dcp_mappluto_archive_16v1_mappluto_16v1.zip \
	../output/dcp_mappluto_archive_16v2_mappluto_16v2.zip ../output/dcp_mappluto_archive_17v1_mappluto_17v1.zip \
	../output/dcp_mappluto_archive_17v1.1_mappluto_17v1_1.zip

../../fetch_mappluto_archive/output/mappluto_files.csv \
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
	../../fetch_mappluto_archive/output/dcp_pluto_archive_18v1_nyc_pluto_18v1.zip \
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
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_17v1.1_mappluto_17v1_1.zip: check-fetch_mappluto_archive ;

link-inputs: ../input/source_files.csv ../input/mappluto_files.csv ../input/nyc_mappluto_18v1_1_arc_shp.zip \
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
	../input/nyc_pluto_18v1.zip ../input/mappluto_09v1.zip ../input/mappluto_09v2.zip ../input/mappluto_10v1.zip \
	../input/mappluto_10v2.zip ../input/mappluto_11v1.zip ../input/mappluto_11v2.zip ../input/mappluto_12v1.zip \
	../input/mappluto_12v2.zip ../input/mappluto_13v1.zip ../input/mappluto_13v2.zip ../input/mappluto_14v1.zip \
	../input/mappluto_14v2.zip ../input/mappluto_15v1.zip ../input/mappluto_16v1.zip ../input/mappluto_16v2.zip \
	../input/mappluto_17v1.zip ../input/mappluto_17v1_1.zip

include ../../shared/code/generic.make
