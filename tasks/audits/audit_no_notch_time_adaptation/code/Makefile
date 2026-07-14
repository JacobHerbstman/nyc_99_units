SHELL := bash
include ../../../shell_functions.make

TRAINING_FLOORS := 6,11
UNIVERSE_MIN_UNITS := 6
EXPANDING_START_YEAR := 2010
FIRST_TRAIN_END_YEAR := 2015
LAST_TRAIN_END_YEAR := 2021
FINAL_TRAIN_END_YEAR := 2023
ROLLING_YEARS := 5
RECENT_INTERCEPT_YEARS := 2
RISK_MIN_UNITS := 50
RISK_MAX_UNITS := 150
MIN_CATEGORY_ROWS := 30

all: ../output/no_notch_time_adaptation_window_metrics.csv \
	../output/no_notch_time_adaptation_out_of_time_predictions.parquet \
	../output/no_notch_time_adaptation_validation_summary.csv \
	../output/no_notch_time_adaptation_model_ranking.csv \
	../output/no_notch_time_adaptation_model_choice.csv \
	../output/no_notch_time_adaptation_interim_fit_parameters.csv \
	../output/no_notch_time_adaptation_fit_qc.csv \
	../output/no_notch_time_adaptation_sample_qc.csv \
	../output/no_notch_time_adaptation_windows.csv

../output/no_notch_time_adaptation_window_metrics.csv: audit_no_notch_time_adaptation.R ../../../_lib/source_pipeline_utils.R ../input/hdb_mappluto_training_panel.parquet | ../output
	$(R) $< $(TRAINING_FLOORS) $(UNIVERSE_MIN_UNITS) $(EXPANDING_START_YEAR) $(FIRST_TRAIN_END_YEAR) $(LAST_TRAIN_END_YEAR) $(FINAL_TRAIN_END_YEAR) $(ROLLING_YEARS) $(RECENT_INTERCEPT_YEARS) $(RISK_MIN_UNITS) $(RISK_MAX_UNITS) $(MIN_CATEGORY_ROWS)

../output/no_notch_time_adaptation_out_of_time_predictions.parquet ../output/no_notch_time_adaptation_validation_summary.csv ../output/no_notch_time_adaptation_model_ranking.csv ../output/no_notch_time_adaptation_model_choice.csv ../output/no_notch_time_adaptation_interim_fit_parameters.csv ../output/no_notch_time_adaptation_fit_qc.csv ../output/no_notch_time_adaptation_sample_qc.csv ../output/no_notch_time_adaptation_windows.csv: ../output/no_notch_time_adaptation_window_metrics.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet

include ../../generic.make
