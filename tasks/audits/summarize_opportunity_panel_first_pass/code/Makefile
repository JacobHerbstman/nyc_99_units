SHELL := bash
include ../../../shell_functions.make

all: ../output/opportunity_panel_first_pass_period_quartile.csv \
	../output/opportunity_panel_first_pass_regressions.csv \
	../output/opportunity_panel_first_pass_samples.csv \
	../output/opportunity_panel_first_pass_hard_checks.csv

../output/opportunity_panel_first_pass_period_quartile.csv: summarize_opportunity_panel_first_pass.R ../input/opportunity_lot_quarter_panel.parquet | ../output
	$(R) $<

../output/opportunity_panel_first_pass_regressions.csv \
	../output/opportunity_panel_first_pass_samples.csv \
	../output/opportunity_panel_first_pass_hard_checks.csv: ../output/opportunity_panel_first_pass_period_quartile.csv
	@test -s "$@"

../input/opportunity_lot_quarter_panel.parquet: ../../../build_opportunity_lot_quarter_panel/output/opportunity_lot_quarter_panel.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_opportunity_lot_quarter_panel/output/opportunity_lot_quarter_panel.parquet" || ln -sf "../../../build_opportunity_lot_quarter_panel/output/opportunity_lot_quarter_panel.parquet" "$@"

link-inputs: ../input/opportunity_lot_quarter_panel.parquet

include ../../generic.make
