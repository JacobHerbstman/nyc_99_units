include ../../shared/code/shell_functions.make

all: ../output/mappluto_lot_files.csv \
	../report/dcp_mappluto_archive_18v1_1.txt \
	../report/dcp_mappluto_archive_18v2_1.txt \
	../report/dcp_mappluto_archive_18v2beta.txt \
	../report/dcp_mappluto_archive_19v1.txt \
	../report/dcp_mappluto_archive_19v2.txt \
	../report/dcp_mappluto_archive_20v1.txt \
	../report/dcp_mappluto_archive_20v2.txt \
	../report/dcp_mappluto_archive_20v3.txt \
	../report/dcp_mappluto_archive_20v4.txt \
	../report/dcp_mappluto_archive_20v5.txt \
	../report/dcp_mappluto_archive_20v6.txt \
	../report/dcp_mappluto_archive_20v7.txt \
	../report/dcp_mappluto_archive_20v8.txt \
	../report/dcp_mappluto_archive_21v1.txt \
	../report/dcp_mappluto_archive_21v3.txt \
	../report/dcp_mappluto_archive_22v1.txt \
	../report/dcp_mappluto_archive_22v2.txt \
	../report/dcp_mappluto_archive_23v1.txt \
	../report/dcp_mappluto_archive_23v1_1.txt \
	../report/dcp_mappluto_archive_23v1_2.txt \
	../report/dcp_mappluto_archive_23v2.txt \
	../report/dcp_mappluto_archive_23v3.txt \
	../report/dcp_mappluto_archive_23v3_1.txt \
	../report/dcp_pluto_archive_09v1.txt \
	../report/dcp_pluto_archive_09v2.txt \
	../report/dcp_pluto_archive_10v1.txt \
	../report/dcp_pluto_archive_10v2.txt \
	../report/dcp_pluto_archive_11v1.txt \
	../report/dcp_pluto_archive_11v2.txt \
	../report/dcp_pluto_archive_12v1.txt \
	../report/dcp_pluto_archive_12v2.txt \
	../report/dcp_pluto_archive_13v1.txt \
	../report/dcp_pluto_archive_13v2.txt \
	../report/dcp_pluto_archive_14v1.txt \
	../report/dcp_pluto_archive_14v2.txt \
	../report/dcp_pluto_archive_15v1.txt \
	../report/dcp_pluto_archive_16v1.txt \
	../report/dcp_pluto_archive_16v2.txt \
	../report/dcp_pluto_archive_17v1.txt \
	../report/dcp_pluto_archive_17v1_1.txt \
	../report/dcp_pluto_archive_18v1.txt \
	../report/mappluto_lot_files.txt

../output/mappluto_lot_files.csv: index_mappluto_lots.R ../../shared/code/source_pipeline_utils.R Makefile \
	../input/mappluto_raw_files.csv ../output/dcp_mappluto_archive_18v1_1.parquet \
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


../report/dcp_mappluto_archive_18v1_1.txt: report_data.R ../../shared/code/write_data_report.R ../output/dcp_mappluto_archive_18v1_1.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< dcp_mappluto_archive_18v1_1

../report/mappluto_lot_files.txt: report_data.R ../../shared/code/write_data_report.R ../output/mappluto_lot_files.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< mappluto_lot_files



../output/dcp_mappluto_archive_%.parquet: stage_mappluto_lots.R ../../shared/code/source_pipeline_utils.R Makefile ../input/source_files.csv ../input/dcp_mappluto_archive_%_raw.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) stage_mappluto_lots.R dcp_mappluto_archive $*

../output/dcp_pluto_archive_%.parquet: stage_mappluto_lots.R ../../shared/code/source_pipeline_utils.R Makefile ../input/source_files.csv ../input/dcp_pluto_archive_%_raw.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) stage_mappluto_lots.R dcp_pluto_archive $*

../report/dcp_%.txt: report_data.R ../../shared/code/write_data_report.R ../output/dcp_%.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) report_data.R dcp_$*
../input/mappluto_raw_files.csv: ../../load_mappluto_raw/output/mappluto_raw_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_18v1_1_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_18v1_1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_18v2_1_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_18v2_1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_18v2beta_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_18v2beta_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_19v1_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_19v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_19v2_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_19v2_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v1_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_20v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v2_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_20v2_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v3_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_20v3_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v4_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_20v4_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v5_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_20v5_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v6_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_20v6_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v7_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_20v7_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v8_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_20v8_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_21v1_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_21v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_21v3_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_21v3_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_22v1_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_22v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_22v2_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_22v2_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v1_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_23v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v1_1_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_23v1_1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v1_2_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_23v1_2_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v2_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_23v2_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v3_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_23v3_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v3_1_raw.parquet: ../../load_mappluto_raw/output/dcp_mappluto_archive_23v3_1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_09v1_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_09v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_09v2_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_09v2_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_10v1_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_10v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_10v2_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_10v2_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_11v1_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_11v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_11v2_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_11v2_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_12v1_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_12v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_12v2_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_12v2_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_13v1_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_13v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_13v2_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_13v2_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_14v1_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_14v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_14v2_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_14v2_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_15v1_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_15v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_16v1_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_16v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_16v2_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_16v2_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_17v1_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_17v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_17v1_1_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_17v1_1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_18v1_raw.parquet: ../../load_mappluto_raw/output/dcp_pluto_archive_18v1_raw.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/source_files.csv: ../../fetch_mappluto_archive/code/source_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../load_mappluto_raw/output/mappluto_raw_files.csv \
	../../load_mappluto_raw/output/dcp_mappluto_archive_18v1_1_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_18v2_1_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_18v2beta_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_19v1_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_19v2_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_20v1_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_20v2_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_20v3_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_20v4_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_20v5_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_20v6_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_20v7_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_20v8_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_21v1_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_21v3_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_22v1_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_22v2_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_23v1_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_23v1_1_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_23v1_2_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_23v2_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_23v3_raw.parquet \
	../../load_mappluto_raw/output/dcp_mappluto_archive_23v3_1_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_09v1_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_09v2_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_10v1_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_10v2_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_11v1_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_11v2_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_12v1_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_12v2_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_13v1_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_13v2_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_14v1_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_14v2_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_15v1_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_16v1_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_16v2_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_17v1_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_17v1_1_raw.parquet \
	../../load_mappluto_raw/output/dcp_pluto_archive_18v1_raw.parquet: check-load_mappluto_raw ;

.PHONY: check-load_mappluto_raw

check-load_mappluto_raw:
	$(MAKE) -C ../../load_mappluto_raw/code all ../output/mappluto_raw_files.csv ../output/dcp_mappluto_archive_18v1_1_raw.parquet ../output/dcp_mappluto_archive_18v2_1_raw.parquet ../output/dcp_mappluto_archive_18v2beta_raw.parquet ../output/dcp_mappluto_archive_19v1_raw.parquet ../output/dcp_mappluto_archive_19v2_raw.parquet ../output/dcp_mappluto_archive_20v1_raw.parquet ../output/dcp_mappluto_archive_20v2_raw.parquet ../output/dcp_mappluto_archive_20v3_raw.parquet ../output/dcp_mappluto_archive_20v4_raw.parquet ../output/dcp_mappluto_archive_20v5_raw.parquet ../output/dcp_mappluto_archive_20v6_raw.parquet ../output/dcp_mappluto_archive_20v7_raw.parquet ../output/dcp_mappluto_archive_20v8_raw.parquet ../output/dcp_mappluto_archive_21v1_raw.parquet ../output/dcp_mappluto_archive_21v3_raw.parquet ../output/dcp_mappluto_archive_22v1_raw.parquet ../output/dcp_mappluto_archive_22v2_raw.parquet ../output/dcp_mappluto_archive_23v1_raw.parquet ../output/dcp_mappluto_archive_23v1_1_raw.parquet ../output/dcp_mappluto_archive_23v1_2_raw.parquet ../output/dcp_mappluto_archive_23v2_raw.parquet ../output/dcp_mappluto_archive_23v3_raw.parquet ../output/dcp_mappluto_archive_23v3_1_raw.parquet ../output/dcp_pluto_archive_09v1_raw.parquet ../output/dcp_pluto_archive_09v2_raw.parquet ../output/dcp_pluto_archive_10v1_raw.parquet ../output/dcp_pluto_archive_10v2_raw.parquet ../output/dcp_pluto_archive_11v1_raw.parquet ../output/dcp_pluto_archive_11v2_raw.parquet ../output/dcp_pluto_archive_12v1_raw.parquet ../output/dcp_pluto_archive_12v2_raw.parquet ../output/dcp_pluto_archive_13v1_raw.parquet ../output/dcp_pluto_archive_13v2_raw.parquet ../output/dcp_pluto_archive_14v1_raw.parquet ../output/dcp_pluto_archive_14v2_raw.parquet ../output/dcp_pluto_archive_15v1_raw.parquet ../output/dcp_pluto_archive_16v1_raw.parquet ../output/dcp_pluto_archive_16v2_raw.parquet ../output/dcp_pluto_archive_17v1_raw.parquet ../output/dcp_pluto_archive_17v1_1_raw.parquet ../output/dcp_pluto_archive_18v1_raw.parquet

include ../../shared/code/generic.make
