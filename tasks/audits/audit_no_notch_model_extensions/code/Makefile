SHELL := bash
include ../../../shell_functions.make

MIN_UNITS := 6
LOCAL_MIN_UNITS := 50
LOCAL_MAX_UNITS := 150
MIN_CATEGORY_ROWS := 30

all: ../output/no_notch_extension_comparison.csv \
	../output/no_notch_extension_window_metrics.csv \
	../output/no_notch_extension_window_comparison.csv \
	../output/no_notch_extension_status.csv \
	../output/no_notch_extension_design_qc.csv \
	../output/no_notch_extension_address_summary.csv \
	../output/no_notch_extension_tail_cases.csv \
	../output/no_notch_reference_model_summary.txt \
	../output/no_notch_reference_model_coefficients.csv \
	../output/no_notch_reference_residual_summary.csv \
	../output/no_notch_extension_predictions.parquet \
	../output/no_notch_extension_diagnostics.pdf \
	../output/no_notch_extension_diagnostics.png

../output/no_notch_extension_comparison.csv: audit_no_notch_model_extensions.R ../../../_lib/source_pipeline_utils.R ../input/hdb_mappluto_training_panel.parquet ../input/no_notch_time_windows.csv | ../output
	$(R) $< $(MIN_UNITS) $(LOCAL_MIN_UNITS) $(LOCAL_MAX_UNITS) $(MIN_CATEGORY_ROWS)

../output/no_notch_extension_window_metrics.csv ../output/no_notch_extension_window_comparison.csv ../output/no_notch_extension_status.csv ../output/no_notch_extension_design_qc.csv ../output/no_notch_extension_address_summary.csv ../output/no_notch_extension_tail_cases.csv ../output/no_notch_reference_model_summary.txt ../output/no_notch_reference_model_coefficients.csv ../output/no_notch_reference_residual_summary.csv ../output/no_notch_extension_predictions.parquet ../output/no_notch_extension_diagnostics.pdf ../output/no_notch_extension_diagnostics.png: ../output/no_notch_extension_comparison.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/no_notch_time_windows.csv: ../../audit_no_notch_unit_distribution/output/no_notch_time_windows.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet ../input/no_notch_time_windows.csv

include ../../generic.make
