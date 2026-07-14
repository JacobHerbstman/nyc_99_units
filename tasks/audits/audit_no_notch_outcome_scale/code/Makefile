SHELL := bash
include ../../../shell_functions.make

MIN_UNITS := 6
LOCAL_MIN_UNITS := 50
LOCAL_MAX_UNITS := 150
MIN_CATEGORY_ROWS := 30

all: ../output/no_notch_outcome_scale_window_metrics.csv \
	../output/no_notch_outcome_scale_validation_summary.csv \
	../output/no_notch_outcome_scale_prediction_qc.csv \
	../output/no_notch_outcome_scale_reference_predictions.parquet \
	../output/no_notch_outcome_scale_reference_summary.txt

../output/no_notch_outcome_scale_window_metrics.csv: audit_no_notch_outcome_scale.R ../input/hdb_mappluto_training_panel.parquet ../input/no_notch_time_windows.csv | ../output
	$(R) $< $(MIN_UNITS) $(LOCAL_MIN_UNITS) $(LOCAL_MAX_UNITS) $(MIN_CATEGORY_ROWS)

../output/no_notch_outcome_scale_validation_summary.csv ../output/no_notch_outcome_scale_prediction_qc.csv ../output/no_notch_outcome_scale_reference_predictions.parquet ../output/no_notch_outcome_scale_reference_summary.txt: ../output/no_notch_outcome_scale_window_metrics.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/no_notch_time_windows.csv: ../../audit_no_notch_unit_distribution/output/no_notch_time_windows.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet ../input/no_notch_time_windows.csv

include ../../generic.make
