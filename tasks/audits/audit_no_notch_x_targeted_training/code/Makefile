SHELL := bash
include ../../../shell_functions.make

UNIVERSE_MIN_UNITS := 6
ALTERNATIVE_FLOOR := 11
RISK_MIN_UNITS := 50
RISK_MAX_UNITS := 150
KERNEL_CENTER_UNITS := 100
KERNEL_BANDWIDTH_LOG := 0.6931471805599453
MIN_CATEGORY_ROWS := 30

all: ../output/no_notch_x_targeted_window_metrics.csv \
	../output/no_notch_x_targeted_validation_summary.csv \
	../output/no_notch_x_targeted_training_diagnostics.csv \
	../output/no_notch_x_targeted_reference_predictions.parquet \
	../output/no_notch_x_targeted_reference_fit_summary.txt

../output/no_notch_x_targeted_window_metrics.csv: audit_no_notch_x_targeted_training.R ../input/hdb_mappluto_training_panel.parquet ../input/no_notch_time_windows.csv | ../output
	$(R) $< $(UNIVERSE_MIN_UNITS) $(ALTERNATIVE_FLOOR) $(RISK_MIN_UNITS) $(RISK_MAX_UNITS) $(KERNEL_CENTER_UNITS) $(KERNEL_BANDWIDTH_LOG) $(MIN_CATEGORY_ROWS)

../output/no_notch_x_targeted_validation_summary.csv ../output/no_notch_x_targeted_training_diagnostics.csv ../output/no_notch_x_targeted_reference_predictions.parquet ../output/no_notch_x_targeted_reference_fit_summary.txt: ../output/no_notch_x_targeted_window_metrics.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/no_notch_time_windows.csv: ../../audit_no_notch_unit_distribution/output/no_notch_time_windows.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet ../input/no_notch_time_windows.csv

include ../../generic.make
