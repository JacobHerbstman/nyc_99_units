SHELL := bash
include ../../shell_functions.make

all: ../output/mappluto_opportunity_lots_frozen.parquet

../output/mappluto_opportunity_lots_frozen.parquet: build_frozen_opportunity_lots.R ../input/mappluto_lot_files.csv ../input/mappluto_release_calendar.csv | ../output
	$(R) $<

../input/mappluto_lot_files.csv: ../../stage_mappluto_lots/output/mappluto_lot_files.csv | ../input
	@test "$$(readlink "$@")" = "../../stage_mappluto_lots/output/mappluto_lot_files.csv" || ln -sf "../../stage_mappluto_lots/output/mappluto_lot_files.csv" "$@"

../input/mappluto_release_calendar.csv: ../../define_mappluto_release_calendar/output/mappluto_release_calendar.csv | ../input
	@test "$$(readlink "$@")" = "../../define_mappluto_release_calendar/output/mappluto_release_calendar.csv" || ln -sf "../../define_mappluto_release_calendar/output/mappluto_release_calendar.csv" "$@"

link-inputs: ../input/mappluto_lot_files.csv ../input/mappluto_release_calendar.csv

include ../../generic.make
