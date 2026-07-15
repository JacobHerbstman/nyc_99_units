SHELL := bash
include ../../../shell_functions.make

UNIVERSE_MIN_UNITS := 6
THRESHOLD_UNITS := 100

all: ../output/no_notch_mass_balance_summary.csv \
	../output/no_notch_mass_balance_curve.csv \
	../output/no_notch_mass_balance_curve.pdf \
	../output/no_notch_mass_balance_curve.png

../output/no_notch_mass_balance_summary.csv: audit_no_notch_mass_balance.R ../input/no_notch_post_policy_exposure_scores.parquet | ../output
	$(R) $< $(UNIVERSE_MIN_UNITS) $(THRESHOLD_UNITS)

../output/no_notch_mass_balance_curve.csv ../output/no_notch_mass_balance_curve.pdf ../output/no_notch_mass_balance_curve.png: ../output/no_notch_mass_balance_summary.csv
	@test -s "$@"

../input/no_notch_post_policy_exposure_scores.parquet: ../../audit_no_notch_post_policy_exposure/output/no_notch_post_policy_exposure_scores.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/no_notch_post_policy_exposure_scores.parquet

include ../../generic.make
