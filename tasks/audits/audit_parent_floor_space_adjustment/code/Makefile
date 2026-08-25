SHELL := bash
include ../../../shell_functions.make

TRAIN_START_YEAR := 2021
TRAIN_END_YEAR := 2022
POST_YEAR := 2025
MIN_UNITS := 50
MAX_UNITS := 150
BUNCH_UNITS := 99
MIN_GROSS_SQFT_PER_UNIT := 300
MIN_CATEGORY_ROWS := 10
NO_NOTCH_MIN_UNITS := 6

all: ../output/parent_floor_space_ledger.csv \
	../output/parent_floor_space_summary.csv \
	../output/parent_floor_space_model_diagnostics.csv \
	../output/parent_floor_space_model_coefficients.csv \
	../output/parent_floor_space_adjustment.pdf \
	../output/parent_floor_space_adjustment.png

../output/parent_floor_space_ledger.csv: audit_parent_floor_space_adjustment.R \
	../input/historical_enhanced_parent_model_panel.parquet \
	../input/post_policy_enhanced_parent_model_panel.parquet \
	../input/symmetric_parent_membership.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/enhanced_parent_2025_scores.parquet \
	../input/enhanced_parent_2025_counterfactual.csv \
	../input/hpd_485x_parent_registration_summary.csv \
	../../../_lib/parent_no_notch_model.R | ../output
	$(R) $< $(TRAIN_START_YEAR) $(TRAIN_END_YEAR) $(POST_YEAR) \
		$(MIN_UNITS) $(MAX_UNITS) $(BUNCH_UNITS) \
		$(MIN_GROSS_SQFT_PER_UNIT) $(MIN_CATEGORY_ROWS) \
		$(NO_NOTCH_MIN_UNITS)

../output/parent_floor_space_summary.csv \
../output/parent_floor_space_model_diagnostics.csv \
../output/parent_floor_space_model_coefficients.csv \
../output/parent_floor_space_adjustment.pdf \
../output/parent_floor_space_adjustment.png: ../output/parent_floor_space_ledger.csv
	@test -s "$@"

../input/historical_enhanced_parent_model_panel.parquet: ../../../build_parent_model_panel/output/historical_enhanced_parent_model_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_enhanced_parent_model_panel.parquet: ../../../build_parent_model_panel/output/post_policy_enhanced_parent_model_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/enhanced_parent_2025_scores.parquet: ../../../estimate_parent_no_notch_model/output/enhanced_parent_2025_scores.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/enhanced_parent_2025_counterfactual.csv: ../../../estimate_parent_no_notch_model/output/enhanced_parent_2025_counterfactual.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hpd_485x_parent_registration_summary.csv: ../../audit_hpd_485x_registration_linkage/output/hpd_485x_parent_registration_summary.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/historical_enhanced_parent_model_panel.parquet \
	../input/post_policy_enhanced_parent_model_panel.parquet \
	../input/symmetric_parent_membership.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/enhanced_parent_2025_scores.parquet \
	../input/enhanced_parent_2025_counterfactual.csv \
	../input/hpd_485x_parent_registration_summary.csv

include ../../generic.make
