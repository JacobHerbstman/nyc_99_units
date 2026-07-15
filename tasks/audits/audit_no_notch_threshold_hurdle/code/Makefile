SHELL := bash
include ../../../shell_functions.make

MIN_UNITS := 6
MIN_CATEGORY_ROWS := 30
CUTOFFS := 11,20,30,40

all: ../output/no_notch_threshold_hurdle_validation_summary.csv \
	../output/no_notch_threshold_hurdle_window_metrics.csv \
	../output/no_notch_threshold_hurdle_status.csv \
	../output/no_notch_threshold_hurdle_reference_predictions.parquet

../output/no_notch_threshold_hurdle_validation_summary.csv: audit_no_notch_threshold_hurdle.R ../../../_lib/source_pipeline_utils.R ../input/hdb_mappluto_training_panel.parquet ../input/no_notch_time_windows.csv | ../output
	$(R) $< $(MIN_UNITS) $(MIN_CATEGORY_ROWS) $(CUTOFFS)

../output/no_notch_threshold_hurdle_window_metrics.csv ../output/no_notch_threshold_hurdle_status.csv ../output/no_notch_threshold_hurdle_reference_predictions.parquet: ../output/no_notch_threshold_hurdle_validation_summary.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/no_notch_time_windows.csv: ../../audit_no_notch_unit_distribution/output/no_notch_time_windows.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet ../input/no_notch_time_windows.csv

include ../../generic.make
