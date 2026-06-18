SHELL := bash
include ../../../shell_functions.make

all: ../output/private_market_sale_hard_checks.csv \
	../output/private_market_sale_event_column_audit.csv \
	../output/private_market_sale_incidence_column_audit.csv \
	../output/private_market_sale_event_category_counts.csv \
	../output/private_market_sale_incidence_category_counts.csv \
	../output/private_market_sale_event_flag_counts.csv \
	../output/private_market_sale_incidence_flag_counts.csv \
	../output/private_market_sale_event_denominator_completeness.csv \
	../output/private_market_sale_incidence_denominator_completeness.csv \
	../output/private_market_sale_price_distributions.csv \
	../output/private_market_sale_examples_by_category.csv \
	../output/private_market_sale_event_audit_ledger.csv \
	../output/private_market_sale_incidence_audit_ledger.csv

../output/private_market_sale_hard_checks.csv: audit_acris_private_market_sales_layer.R ../input/acris_private_market_site_sale_events.parquet ../input/acris_private_market_site_sale_bbl_incidence.parquet | ../output
	$(R) $<

../output/private_market_sale_event_column_audit.csv: ../output/private_market_sale_hard_checks.csv
	@test -s "$@"

../output/private_market_sale_incidence_column_audit.csv: ../output/private_market_sale_hard_checks.csv
	@test -s "$@"

../output/private_market_sale_event_category_counts.csv: ../output/private_market_sale_hard_checks.csv
	@test -s "$@"

../output/private_market_sale_incidence_category_counts.csv: ../output/private_market_sale_hard_checks.csv
	@test -s "$@"

../output/private_market_sale_event_flag_counts.csv: ../output/private_market_sale_hard_checks.csv
	@test -s "$@"

../output/private_market_sale_incidence_flag_counts.csv: ../output/private_market_sale_hard_checks.csv
	@test -s "$@"

../output/private_market_sale_event_denominator_completeness.csv: ../output/private_market_sale_hard_checks.csv
	@test -s "$@"

../output/private_market_sale_incidence_denominator_completeness.csv: ../output/private_market_sale_hard_checks.csv
	@test -s "$@"

../output/private_market_sale_price_distributions.csv: ../output/private_market_sale_hard_checks.csv
	@test -s "$@"

../output/private_market_sale_examples_by_category.csv: ../output/private_market_sale_hard_checks.csv
	@test -s "$@"

../output/private_market_sale_event_audit_ledger.csv: ../output/private_market_sale_hard_checks.csv
	@test -s "$@"

../output/private_market_sale_incidence_audit_ledger.csv: ../output/private_market_sale_hard_checks.csv
	@test -s "$@"

../input/acris_private_market_site_sale_events.parquet: ../../../build_acris_private_market_site_sales/output/acris_private_market_site_sale_events.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_private_market_site_sale_bbl_incidence.parquet: ../../../build_acris_private_market_site_sales/output/acris_private_market_site_sale_bbl_incidence.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/acris_private_market_site_sale_events.parquet ../input/acris_private_market_site_sale_bbl_incidence.parquet

include ../../generic.make
