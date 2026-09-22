include ../../../shared/code/shell_functions.make

all: ../output/mappluto_lot_staging_zip_selection.csv ../output/mappluto_lot_staging_qc.csv \
	../output/mappluto_lot_staging_borough_counts.csv \
	../output/mappluto_lot_staging_zip_selection.csv

../output/mappluto_lot_staging_zip_selection.csv: summarize_mappluto_lot_staging.R ../input/mappluto_lot_files.csv \
	Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/mappluto_lot_staging_borough_counts.csv: ../output/mappluto_lot_staging_qc.csv
	$(RECOVER) -W summarize_mappluto_lot_staging.R all

../output/mappluto_lot_staging_qc.csv: ../output/mappluto_lot_staging_zip_selection.csv
	$(RECOVER) -W summarize_mappluto_lot_staging.R all

../input/mappluto_lot_files.csv: ../../../stage_mappluto_lots/output/mappluto_lot_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/mappluto_lot_files.csv

../../../stage_mappluto_lots/output/mappluto_lot_files.csv: check-stage_mappluto_lots ;

.PHONY: check-stage_mappluto_lots

check-stage_mappluto_lots:
	$(MAKE) -C ../../../stage_mappluto_lots/code all ../output/mappluto_lot_files.csv

include ../../../shared/code/generic.make
