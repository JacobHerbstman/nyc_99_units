SHELL := bash

all: ../output/mappluto_lot_staging_qc.csv ../output/mappluto_lot_staging_borough_counts.csv ../output/mappluto_lot_staging_zip_selection.csv

../output/mappluto_lot_staging_qc.csv: summarize_mappluto_lot_staging.R ../input/mappluto_lot_files.csv | ../output
	$(R) $<

../output/mappluto_lot_staging_borough_counts.csv: ../output/mappluto_lot_staging_qc.csv
	@test -s "$@"

../output/mappluto_lot_staging_zip_selection.csv: ../output/mappluto_lot_staging_qc.csv
	@test -s "$@"

../input/mappluto_lot_files.csv: ../../../stage_mappluto_lots/output/mappluto_lot_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/mappluto_lot_files.csv

include ../../generic.make
