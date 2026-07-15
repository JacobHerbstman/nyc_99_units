SHELL := bash
include ../../../shell_functions.make

POST_YEAR := 2025
UNIVERSE_MIN_UNITS := 6
THRESHOLD_UNITS := 100
PLOT_MIN_UNITS := 50
PLOT_MAX_UNITS := 150
MIN_CATEGORY_ROWS := 30
EXPOSURE_THRESHOLD_LOW := 0.50
EXPOSURE_THRESHOLD_HIGH := 0.75

all: ../output/no_notch_post_policy_exposure_scores.parquet \
	../output/no_notch_post_policy_exact_99_ledger.csv \
	../output/no_notch_post_policy_distribution_counts.csv \
	../output/no_notch_post_policy_aggregate_summary.csv \
	../output/no_notch_post_policy_sample_qc.csv \
	../output/no_notch_post_policy_distribution.pdf \
	../output/no_notch_post_policy_distribution.png

../output/no_notch_post_policy_exposure_scores.parquet: audit_no_notch_post_policy_exposure.R ../input/hdb_mappluto_training_panel.parquet ../input/no_notch_time_adaptation_interim_fit_parameters.csv ../input/developer_response_application_panel.parquet | ../output
	$(R) $< $(POST_YEAR) $(UNIVERSE_MIN_UNITS) $(THRESHOLD_UNITS) $(PLOT_MIN_UNITS) $(PLOT_MAX_UNITS) $(MIN_CATEGORY_ROWS) $(EXPOSURE_THRESHOLD_LOW) $(EXPOSURE_THRESHOLD_HIGH)

../output/no_notch_post_policy_exact_99_ledger.csv ../output/no_notch_post_policy_distribution_counts.csv ../output/no_notch_post_policy_aggregate_summary.csv ../output/no_notch_post_policy_sample_qc.csv ../output/no_notch_post_policy_distribution.pdf ../output/no_notch_post_policy_distribution.png: ../output/no_notch_post_policy_exposure_scores.parquet
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/no_notch_time_adaptation_interim_fit_parameters.csv: ../../audit_no_notch_time_adaptation/output/no_notch_time_adaptation_interim_fit_parameters.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/developer_response_application_panel.parquet: ../../audit_developer_responses/output/developer_response_application_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet ../input/no_notch_time_adaptation_interim_fit_parameters.csv ../input/developer_response_application_panel.parquet

include ../../generic.make
