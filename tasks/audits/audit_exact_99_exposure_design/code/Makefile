SHELL := bash
include ../../../shell_functions.make

POST_YEAR := 2025
BUNCH_UNITS := 99
EXPOSURE_CUT_1 := 0.25
EXPOSURE_CUT_2 := 0.50
EXPOSURE_CUT_3 := 0.75

all: ../output/exact_99_exposure_design_ledger.csv \
	../output/exact_99_exposure_design_summary.csv \
	../output/exact_99_exposure_design_correlations.csv \
	../output/exact_99_exposure_design.pdf \
	../output/exact_99_exposure_design.png

../output/exact_99_exposure_design_ledger.csv: audit_exact_99_exposure_design.R ../input/no_notch_post_policy_exposure_scores.parquet ../input/developer_response_application_panel.parquet | ../output
	$(R) $< $(POST_YEAR) $(BUNCH_UNITS) $(EXPOSURE_CUT_1) $(EXPOSURE_CUT_2) $(EXPOSURE_CUT_3)

../output/exact_99_exposure_design_summary.csv ../output/exact_99_exposure_design_correlations.csv ../output/exact_99_exposure_design.pdf ../output/exact_99_exposure_design.png: ../output/exact_99_exposure_design_ledger.csv
	@test -s "$@"

../input/no_notch_post_policy_exposure_scores.parquet: ../../audit_no_notch_post_policy_exposure/output/no_notch_post_policy_exposure_scores.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/developer_response_application_panel.parquet: ../../audit_developer_responses/output/developer_response_application_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/no_notch_post_policy_exposure_scores.parquet ../input/developer_response_application_panel.parquet

include ../../generic.make
