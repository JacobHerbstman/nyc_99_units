SHELL := bash
include ../../../shell_functions.make

all: ../output/market_site_sale_hard_checks.csv ../output/market_site_sale_event_status_counts.csv ../output/market_site_sale_exclusion_code_counts.csv ../output/market_site_sale_attrition_by_year_borough.csv ../output/market_site_sale_allocation_reconciliation.csv ../output/market_site_sale_price_outliers.csv ../output/market_site_sale_cluster_risk.csv

../output/market_site_sale_hard_checks.csv: summarize_acris_market_site_sale_universe.R ../input/market_site_sale_events.parquet ../input/market_site_sale_event_bbl_incidence.parquet ../input/acris_deed_document_classified.parquet ../input/acris_document_cluster_candidates.parquet | ../output
	$(R) $<

../output/market_site_sale_event_status_counts.csv: ../output/market_site_sale_hard_checks.csv
	@test -s "$@"

../output/market_site_sale_exclusion_code_counts.csv: ../output/market_site_sale_hard_checks.csv
	@test -s "$@"

../output/market_site_sale_attrition_by_year_borough.csv: ../output/market_site_sale_hard_checks.csv
	@test -s "$@"

../output/market_site_sale_allocation_reconciliation.csv: ../output/market_site_sale_hard_checks.csv
	@test -s "$@"

../output/market_site_sale_price_outliers.csv: ../output/market_site_sale_hard_checks.csv
	@test -s "$@"

../output/market_site_sale_cluster_risk.csv: ../output/market_site_sale_hard_checks.csv
	@test -s "$@"

../input/market_site_sale_events.parquet: ../../../build_acris_market_site_sale_universe/output/market_site_sale_events.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/market_site_sale_event_bbl_incidence.parquet: ../../../build_acris_market_site_sale_universe/output/market_site_sale_event_bbl_incidence.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_deed_document_classified.parquet: ../../../build_acris_market_site_sale_universe/output/acris_deed_document_classified.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_document_cluster_candidates.parquet: ../../../build_acris_market_site_sale_universe/output/acris_document_cluster_candidates.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/market_site_sale_events.parquet ../input/market_site_sale_event_bbl_incidence.parquet ../input/acris_deed_document_classified.parquet ../input/acris_document_cluster_candidates.parquet

include ../../generic.make
