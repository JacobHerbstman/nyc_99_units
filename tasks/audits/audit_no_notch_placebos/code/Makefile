SHELL := bash
include ../../../shell_functions.make

UNIVERSE_MIN_UNITS := 6
PLACEBO_THRESHOLDS := 90,100,110,120
POST_YEAR := 2025

all: ../output/no_notch_placebo_moments.csv \
	../output/no_notch_placebo_summary.csv \
	../output/no_notch_placebo_heatmap.pdf \
	../output/no_notch_placebo_heatmap.png

../output/no_notch_placebo_moments.csv: audit_no_notch_placebos.R ../input/no_notch_time_adaptation_out_of_time_predictions.parquet ../input/no_notch_post_policy_exposure_scores.parquet | ../output
	$(R) $< $(UNIVERSE_MIN_UNITS) $(PLACEBO_THRESHOLDS) $(POST_YEAR)

../output/no_notch_placebo_summary.csv ../output/no_notch_placebo_heatmap.pdf ../output/no_notch_placebo_heatmap.png: ../output/no_notch_placebo_moments.csv
	@test -s "$@"

../input/no_notch_time_adaptation_out_of_time_predictions.parquet: ../../audit_no_notch_time_adaptation/output/no_notch_time_adaptation_out_of_time_predictions.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/no_notch_post_policy_exposure_scores.parquet: ../../audit_no_notch_post_policy_exposure/output/no_notch_post_policy_exposure_scores.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/no_notch_time_adaptation_out_of_time_predictions.parquet ../input/no_notch_post_policy_exposure_scores.parquet

include ../../generic.make
