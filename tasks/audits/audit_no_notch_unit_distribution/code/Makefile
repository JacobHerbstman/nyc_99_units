SHELL := bash
include ../../../shell_functions.make

MIN_UNITS := 6
LOCAL_MIN_UNITS := 50
LOCAL_MAX_UNITS := 150
MIN_CATEGORY_ROWS := 30
BOOTSTRAP_REPS := 200
SEED := 20260710

all: ../output/no_notch_model_window_summary.csv \
	../output/no_notch_sample_qc.csv \
	../output/no_notch_time_windows.csv \
	../output/no_notch_model_status.csv \
	../output/no_notch_cdf_calibration.csv \
	../output/no_notch_interval_calibration.csv \
	../output/no_notch_model_ranking.csv \
	../output/no_notch_model_comparison.csv \
	../output/no_notch_shock_parameters.csv \
	../output/no_notch_reference_coefficients.csv \
	../output/no_notch_heldout_predictions.parquet \
	../output/no_notch_bootstrap_metrics.csv \
	../output/no_notch_bootstrap_summary.csv \
	../output/no_notch_bootstrap_status.csv \
	../output/no_notch_histogram_validation.pdf \
	../output/no_notch_predicted_actual_dashboard.pdf \
	../output/no_notch_predicted_actual_dashboard.png \
	../output/no_notch_individual_prediction_bins.csv \
	../output/no_notch_probability_calibration_bins.csv \
	../output/no_notch_window_threshold_comparison.csv

../output/no_notch_model_window_summary.csv: audit_no_notch_unit_distribution.R ../input/hdb_mappluto_training_panel.parquet | ../output
	$(R) $< $(MIN_UNITS) $(LOCAL_MIN_UNITS) $(LOCAL_MAX_UNITS) $(MIN_CATEGORY_ROWS) $(BOOTSTRAP_REPS) $(SEED)

../output/no_notch_sample_qc.csv ../output/no_notch_time_windows.csv ../output/no_notch_model_status.csv ../output/no_notch_cdf_calibration.csv ../output/no_notch_interval_calibration.csv ../output/no_notch_model_ranking.csv ../output/no_notch_model_comparison.csv ../output/no_notch_shock_parameters.csv ../output/no_notch_reference_coefficients.csv ../output/no_notch_heldout_predictions.parquet ../output/no_notch_bootstrap_metrics.csv ../output/no_notch_bootstrap_summary.csv ../output/no_notch_bootstrap_status.csv ../output/no_notch_histogram_validation.pdf: ../output/no_notch_model_window_summary.csv
	@test -s "$@"

../output/no_notch_predicted_actual_dashboard.pdf: plot_no_notch_predicted_actual.R ../output/no_notch_heldout_predictions.parquet ../output/no_notch_bootstrap_summary.csv ../output/no_notch_time_windows.csv | ../output
	$(R) $<

../output/no_notch_predicted_actual_dashboard.png ../output/no_notch_individual_prediction_bins.csv ../output/no_notch_probability_calibration_bins.csv ../output/no_notch_window_threshold_comparison.csv: ../output/no_notch_predicted_actual_dashboard.pdf
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet

include ../../generic.make
