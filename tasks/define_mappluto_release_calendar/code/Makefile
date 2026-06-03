SHELL := bash
include ../../shell_functions.make

all: ../output/mappluto_release_calendar.csv

../output/mappluto_release_calendar.csv: define_mappluto_release_calendar.R mappluto_release_calendar_manual.csv ../input/mappluto_lot_files.csv | ../output
	$(R) $<

../input/mappluto_lot_files.csv: ../../stage_mappluto_lots/output/mappluto_lot_files.csv | ../input
	@test "$$(readlink "$@")" = "../../stage_mappluto_lots/output/mappluto_lot_files.csv" || ln -sf "../../stage_mappluto_lots/output/mappluto_lot_files.csv" "$@"

link-inputs: ../input/mappluto_lot_files.csv

include ../../generic.make
