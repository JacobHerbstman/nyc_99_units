SHELL := bash
include ../../shell_functions.make

all: ../output/mappluto_appbbl_crosswalk.csv

../output/mappluto_appbbl_crosswalk.csv: build_mappluto_appbbl_crosswalk.R ../input/mappluto_files.csv | ../output
	$(R) $<

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/mappluto_files.csv

include ../../generic.make
