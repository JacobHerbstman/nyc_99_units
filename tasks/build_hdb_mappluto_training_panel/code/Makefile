SHELL := bash
include ../../shell_functions.make

START_DATE := 2010-01-01
END_DATE := 2025-12-31

all: ../output/hdb_mappluto_training_panel.parquet

../output/hdb_mappluto_training_panel.parquet: build_hdb_mappluto_training_panel.R ../../_lib/source_pipeline_utils.R ../input/dcp_housing_database_project_level_25q4.parquet ../input/mappluto_lot_files.csv ../input/mappluto_release_calendar.csv ../input/mappluto_appbbl_crosswalk.csv | ../output
	$(R) $< $(START_DATE) $(END_DATE)

../input/dcp_housing_database_project_level_25q4.parquet: ../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet" || ln -sf "../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet" "$@"

../input/mappluto_lot_files.csv: ../../stage_mappluto_lots/output/mappluto_lot_files.csv | ../input
	@test "$$(readlink "$@")" = "../../stage_mappluto_lots/output/mappluto_lot_files.csv" || ln -sf "../../stage_mappluto_lots/output/mappluto_lot_files.csv" "$@"

../input/mappluto_release_calendar.csv: ../../define_mappluto_release_calendar/output/mappluto_release_calendar.csv | ../input
	@test "$$(readlink "$@")" = "../../define_mappluto_release_calendar/output/mappluto_release_calendar.csv" || ln -sf "../../define_mappluto_release_calendar/output/mappluto_release_calendar.csv" "$@"

../input/mappluto_appbbl_crosswalk.csv: ../../build_mappluto_appbbl_crosswalk/output/mappluto_appbbl_crosswalk.csv | ../input
	@test "$$(readlink "$@")" = "../../build_mappluto_appbbl_crosswalk/output/mappluto_appbbl_crosswalk.csv" || ln -sf "../../build_mappluto_appbbl_crosswalk/output/mappluto_appbbl_crosswalk.csv" "$@"

link-inputs: ../input/dcp_housing_database_project_level_25q4.parquet ../input/mappluto_lot_files.csv ../input/mappluto_release_calendar.csv ../input/mappluto_appbbl_crosswalk.csv

include ../../generic.make
