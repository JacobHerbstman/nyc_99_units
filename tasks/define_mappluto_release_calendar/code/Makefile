include ../../shared/code/shell_functions.make

all: ../output/mappluto_release_calendar.csv \
	../report/mappluto_release_calendar.txt

../output/mappluto_release_calendar.csv: define_mappluto_release_calendar.R \
	../../shared/code/source_pipeline_utils.R mappluto_release_calendar_manual.csv ../input/mappluto_lot_files.csv \
	Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<


../report/mappluto_release_calendar.txt: report_data.R ../../shared/code/write_data_report.R ../output/mappluto_release_calendar.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< mappluto_release_calendar


../input/mappluto_lot_files.csv: ../../stage_mappluto_lots/output/mappluto_lot_files.csv | ../input
	@test "$$(readlink "$@")" = "../../stage_mappluto_lots/output/mappluto_lot_files.csv" || ln -sf "../../stage_mappluto_lots/output/mappluto_lot_files.csv" "$@"

link-inputs: ../input/mappluto_lot_files.csv

../../stage_mappluto_lots/output/mappluto_lot_files.csv: check-stage_mappluto_lots ;

.PHONY: check-stage_mappluto_lots

check-stage_mappluto_lots:
	$(MAKE) -C ../../stage_mappluto_lots/code all ../output/mappluto_lot_files.csv

include ../../shared/code/generic.make
