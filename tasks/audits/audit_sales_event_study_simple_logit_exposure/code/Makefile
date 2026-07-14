SHELL := bash
include ../../../shell_functions.make

all: ../output/simple_logit_sales_period_did.csv \
	../output/simple_logit_sales_event_study.csv \
	../output/simple_logit_sales_semiannual_period_did.csv \
	../output/simple_logit_sales_semiannual_event_study.csv \
	../output/simple_logit_sales_semiannual_period_summary.csv \
	../output/simple_logit_sales_period_summary.csv \
	../output/simple_logit_sales_exposure_lot_counts.csv \
	../output/simple_logit_sales_reference_model.csv \
	../output/simple_logit_sales_hard_checks.csv \
	../output/simple_logit_sales_event_study_sale_incidence.pdf \
	../output/simple_logit_sales_event_study_log_price.pdf \
	../output/simple_logit_sales_semiannual_event_study_sale_incidence.pdf \
	../output/simple_logit_sales_semiannual_event_study_log_price.pdf

../output/simple_logit_sales_period_did.csv: audit_sales_event_study_simple_logit_exposure.R ../input/hdb_mappluto_training_panel.parquet ../input/opportunity_lot_quarter_panel.parquet | ../output
	$(R) $<

../output/simple_logit_sales_event_study.csv \
	../output/simple_logit_sales_semiannual_period_did.csv \
	../output/simple_logit_sales_semiannual_event_study.csv \
	../output/simple_logit_sales_semiannual_period_summary.csv \
	../output/simple_logit_sales_period_summary.csv \
	../output/simple_logit_sales_exposure_lot_counts.csv \
	../output/simple_logit_sales_reference_model.csv \
	../output/simple_logit_sales_hard_checks.csv \
	../output/simple_logit_sales_event_study_sale_incidence.pdf \
	../output/simple_logit_sales_event_study_log_price.pdf \
	../output/simple_logit_sales_semiannual_event_study_sale_incidence.pdf \
	../output/simple_logit_sales_semiannual_event_study_log_price.pdf: ../output/simple_logit_sales_period_did.csv
	@test -s "$@"

../input/hdb_mappluto_training_panel.parquet: ../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet" || ln -sf "../../../build_hdb_mappluto_training_panel/output/hdb_mappluto_training_panel.parquet" "$@"

../input/opportunity_lot_quarter_panel.parquet: ../../../build_opportunity_lot_quarter_panel/output/opportunity_lot_quarter_panel.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_opportunity_lot_quarter_panel/output/opportunity_lot_quarter_panel.parquet" || ln -sf "../../../build_opportunity_lot_quarter_panel/output/opportunity_lot_quarter_panel.parquet" "$@"

link-inputs: ../input/hdb_mappluto_training_panel.parquet ../input/opportunity_lot_quarter_panel.parquet

include ../../generic.make
