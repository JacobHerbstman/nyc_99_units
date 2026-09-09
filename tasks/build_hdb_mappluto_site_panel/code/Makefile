include ../../shared/code/shell_functions.make

START_DATE := 2010-01-01
END_DATE := 2025-12-31

ifneq ($(filter command,$(origin START_DATE) $(origin END_DATE)),)
$(error These fixed-name outputs use the settings recorded in this Makefile; edit those settings here so Make tracks the change)
endif

all: ../output/hdb_mappluto_site_panel.parquet \
	../report/hdb_mappluto_site_panel.txt

../output/hdb_mappluto_site_panel.parquet: build_hdb_mappluto_site_panel.R \
	../../shared/code/source_pipeline_utils.R ../input/dcp_housing_database_project_level_25q4.parquet \
	../input/mappluto_lot_files.csv ../input/mappluto_release_calendar.csv ../input/mappluto_appbbl_crosswalk.csv \
	Makefile ../input/dcp_mappluto_archive_18v1_1.parquet ../input/dcp_mappluto_archive_18v2_1.parquet \
	../input/dcp_mappluto_archive_18v2beta.parquet ../input/dcp_mappluto_archive_19v1.parquet \
	../input/dcp_mappluto_archive_19v2.parquet ../input/dcp_mappluto_archive_20v1.parquet \
	../input/dcp_mappluto_archive_20v2.parquet ../input/dcp_mappluto_archive_20v3.parquet \
	../input/dcp_mappluto_archive_20v4.parquet ../input/dcp_mappluto_archive_20v5.parquet \
	../input/dcp_mappluto_archive_20v6.parquet ../input/dcp_mappluto_archive_20v7.parquet \
	../input/dcp_mappluto_archive_20v8.parquet ../input/dcp_mappluto_archive_21v1.parquet \
	../input/dcp_mappluto_archive_21v3.parquet ../input/dcp_mappluto_archive_22v1.parquet \
	../input/dcp_mappluto_archive_22v2.parquet ../input/dcp_mappluto_archive_23v1.parquet \
	../input/dcp_mappluto_archive_23v1_1.parquet ../input/dcp_mappluto_archive_23v1_2.parquet \
	../input/dcp_mappluto_archive_23v2.parquet ../input/dcp_mappluto_archive_23v3.parquet \
	../input/dcp_mappluto_archive_23v3_1.parquet ../input/dcp_pluto_archive_09v1.parquet \
	../input/dcp_pluto_archive_09v2.parquet ../input/dcp_pluto_archive_10v1.parquet \
	../input/dcp_pluto_archive_10v2.parquet ../input/dcp_pluto_archive_11v1.parquet \
	../input/dcp_pluto_archive_11v2.parquet ../input/dcp_pluto_archive_12v1.parquet \
	../input/dcp_pluto_archive_12v2.parquet ../input/dcp_pluto_archive_13v1.parquet \
	../input/dcp_pluto_archive_13v2.parquet ../input/dcp_pluto_archive_14v1.parquet \
	../input/dcp_pluto_archive_14v2.parquet ../input/dcp_pluto_archive_15v1.parquet \
	../input/dcp_pluto_archive_16v1.parquet ../input/dcp_pluto_archive_16v2.parquet \
	../input/dcp_pluto_archive_17v1.parquet ../input/dcp_pluto_archive_17v1_1.parquet \
	../input/dcp_pluto_archive_18v1.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $< $(START_DATE) $(END_DATE)


../report/hdb_mappluto_site_panel.txt: report_data.R ../../shared/code/write_data_report.R ../output/hdb_mappluto_site_panel.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< hdb_mappluto_site_panel


../input/dcp_housing_database_project_level_25q4.parquet: ../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet" || ln -sf "../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet" "$@"

../input/mappluto_lot_files.csv: ../../stage_mappluto_lots/output/mappluto_lot_files.csv | ../input
	@test "$$(readlink "$@")" = "../../stage_mappluto_lots/output/mappluto_lot_files.csv" || ln -sf "../../stage_mappluto_lots/output/mappluto_lot_files.csv" "$@"

../input/mappluto_release_calendar.csv: ../../define_mappluto_release_calendar/output/mappluto_release_calendar.csv | ../input
	@test "$$(readlink "$@")" = "../../define_mappluto_release_calendar/output/mappluto_release_calendar.csv" || ln -sf "../../define_mappluto_release_calendar/output/mappluto_release_calendar.csv" "$@"

../input/mappluto_appbbl_crosswalk.csv: ../../build_mappluto_appbbl_crosswalk/output/mappluto_appbbl_crosswalk.csv | ../input
	@test "$$(readlink "$@")" = "../../build_mappluto_appbbl_crosswalk/output/mappluto_appbbl_crosswalk.csv" || ln -sf "../../build_mappluto_appbbl_crosswalk/output/mappluto_appbbl_crosswalk.csv" "$@"

link-inputs: ../input/dcp_housing_database_project_level_25q4.parquet ../input/mappluto_lot_files.csv ../input/mappluto_release_calendar.csv ../input/mappluto_appbbl_crosswalk.csv

../input/dcp_mappluto_archive_18v1_1.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_18v1_1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_18v2_1.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_18v2_1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_18v2beta.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_18v2beta.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_19v1.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_19v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_19v2.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_19v2.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v1.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_20v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v2.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_20v2.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v3.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_20v3.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v4.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_20v4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v5.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_20v5.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v6.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_20v6.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v7.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_20v7.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_20v8.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_20v8.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_21v1.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_21v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_21v3.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_21v3.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_22v1.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_22v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_22v2.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_22v2.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v1.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_23v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v1_1.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_23v1_1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v1_2.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_23v1_2.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v2.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_23v2.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v3.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_23v3.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_mappluto_archive_23v3_1.parquet: ../../stage_mappluto_lots/output/dcp_mappluto_archive_23v3_1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_09v1.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_09v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_09v2.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_09v2.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_10v1.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_10v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_10v2.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_10v2.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_11v1.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_11v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_11v2.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_11v2.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_12v1.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_12v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_12v2.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_12v2.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_13v1.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_13v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_13v2.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_13v2.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_14v1.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_14v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_14v2.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_14v2.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_15v1.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_15v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_16v1.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_16v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_16v2.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_16v2.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_17v1.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_17v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_17v1_1.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_17v1_1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_pluto_archive_18v1.parquet: ../../stage_mappluto_lots/output/dcp_pluto_archive_18v1.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet: check-stage_dcp_housing_database ;

.PHONY: check-stage_dcp_housing_database

check-stage_dcp_housing_database:
	$(MAKE) -C ../../stage_dcp_housing_database/code all ../output/dcp_housing_database_project_level_25q4.parquet

../../stage_mappluto_lots/output/mappluto_lot_files.csv \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_18v1_1.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_18v2_1.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_18v2beta.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_19v1.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_19v2.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_20v1.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_20v2.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_20v3.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_20v4.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_20v5.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_20v6.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_20v7.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_20v8.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_21v1.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_21v3.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_22v1.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_22v2.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_23v1.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_23v1_1.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_23v1_2.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_23v2.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_23v3.parquet \
	../../stage_mappluto_lots/output/dcp_mappluto_archive_23v3_1.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_09v1.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_09v2.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_10v1.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_10v2.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_11v1.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_11v2.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_12v1.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_12v2.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_13v1.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_13v2.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_14v1.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_14v2.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_15v1.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_16v1.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_16v2.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_17v1.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_17v1_1.parquet \
	../../stage_mappluto_lots/output/dcp_pluto_archive_18v1.parquet: check-stage_mappluto_lots ;

.PHONY: check-stage_mappluto_lots

check-stage_mappluto_lots:
	$(MAKE) -C ../../stage_mappluto_lots/code all ../output/mappluto_lot_files.csv ../output/dcp_mappluto_archive_18v1_1.parquet ../output/dcp_mappluto_archive_18v2_1.parquet ../output/dcp_mappluto_archive_18v2beta.parquet ../output/dcp_mappluto_archive_19v1.parquet ../output/dcp_mappluto_archive_19v2.parquet ../output/dcp_mappluto_archive_20v1.parquet ../output/dcp_mappluto_archive_20v2.parquet ../output/dcp_mappluto_archive_20v3.parquet ../output/dcp_mappluto_archive_20v4.parquet ../output/dcp_mappluto_archive_20v5.parquet ../output/dcp_mappluto_archive_20v6.parquet ../output/dcp_mappluto_archive_20v7.parquet ../output/dcp_mappluto_archive_20v8.parquet ../output/dcp_mappluto_archive_21v1.parquet ../output/dcp_mappluto_archive_21v3.parquet ../output/dcp_mappluto_archive_22v1.parquet ../output/dcp_mappluto_archive_22v2.parquet ../output/dcp_mappluto_archive_23v1.parquet ../output/dcp_mappluto_archive_23v1_1.parquet ../output/dcp_mappluto_archive_23v1_2.parquet ../output/dcp_mappluto_archive_23v2.parquet ../output/dcp_mappluto_archive_23v3.parquet ../output/dcp_mappluto_archive_23v3_1.parquet ../output/dcp_pluto_archive_09v1.parquet ../output/dcp_pluto_archive_09v2.parquet ../output/dcp_pluto_archive_10v1.parquet ../output/dcp_pluto_archive_10v2.parquet ../output/dcp_pluto_archive_11v1.parquet ../output/dcp_pluto_archive_11v2.parquet ../output/dcp_pluto_archive_12v1.parquet ../output/dcp_pluto_archive_12v2.parquet ../output/dcp_pluto_archive_13v1.parquet ../output/dcp_pluto_archive_13v2.parquet ../output/dcp_pluto_archive_14v1.parquet ../output/dcp_pluto_archive_14v2.parquet ../output/dcp_pluto_archive_15v1.parquet ../output/dcp_pluto_archive_16v1.parquet ../output/dcp_pluto_archive_16v2.parquet ../output/dcp_pluto_archive_17v1.parquet ../output/dcp_pluto_archive_17v1_1.parquet ../output/dcp_pluto_archive_18v1.parquet

../../define_mappluto_release_calendar/output/mappluto_release_calendar.csv: check-define_mappluto_release_calendar ;

.PHONY: check-define_mappluto_release_calendar

check-define_mappluto_release_calendar:
	$(MAKE) -C ../../define_mappluto_release_calendar/code all ../output/mappluto_release_calendar.csv

../../build_mappluto_appbbl_crosswalk/output/mappluto_appbbl_crosswalk.csv: check-build_mappluto_appbbl_crosswalk ;

.PHONY: check-build_mappluto_appbbl_crosswalk

check-build_mappluto_appbbl_crosswalk:
	$(MAKE) -C ../../build_mappluto_appbbl_crosswalk/code all ../output/mappluto_appbbl_crosswalk.csv

include ../../shared/code/generic.make
