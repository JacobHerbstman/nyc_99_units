SHELL := bash
include ../../../shell_functions.make

all: ../output/dof_acris_coverage_by_year_borough.csv \
	../output/dof_acris_coverage_overall.csv \
	../output/dof_acris_coverage_by_status.csv \
	../output/dof_acris_coverage_by_stratum.csv \
	../output/high_priority_dof_only_cases.csv \
	../output/dof_only_case_examples.csv \
	../output/acris_only_cases.csv \
	../output/dof_opportunity_sale_candidates.parquet \
	../output/dof_acris_link_candidates.parquet \
	../output/dof_acris_best_links.parquet \
	../output/dof_nearest_same_bbl_acris_events.parquet \
	../output/audit_recorded_sales_coverage_hard_checks.csv

../output/dof_acris_coverage_by_year_borough.csv: audit_recorded_sales_coverage.R \
	../../../_lib/source_pipeline_utils.R \
	../input/dof_annualized_sales.parquet \
	../input/acris_private_market_site_sale_events.parquet \
	../input/acris_private_market_site_sale_bbl_incidence.parquet \
	../input/mappluto_opportunity_lots_frozen.parquet | ../output
	$(R) $<

../output/dof_acris_coverage_overall.csv \
	../output/dof_acris_coverage_by_status.csv \
	../output/dof_acris_coverage_by_stratum.csv \
	../output/high_priority_dof_only_cases.csv \
	../output/dof_only_case_examples.csv \
	../output/acris_only_cases.csv \
	../output/dof_opportunity_sale_candidates.parquet \
	../output/dof_acris_link_candidates.parquet \
	../output/dof_acris_best_links.parquet \
	../output/dof_nearest_same_bbl_acris_events.parquet \
	../output/audit_recorded_sales_coverage_hard_checks.csv: ../output/dof_acris_coverage_by_year_borough.csv
	@test -s "$@"

../input/dof_annualized_sales.parquet: ../../../stage_dof_annualized_sales/output/dof_annualized_sales.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_private_market_site_sale_events.parquet: ../../../build_acris_private_market_site_sales/output/acris_private_market_site_sale_events.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_private_market_site_sale_bbl_incidence.parquet: ../../../build_acris_private_market_site_sales/output/acris_private_market_site_sale_bbl_incidence.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_opportunity_lots_frozen.parquet: ../../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dof_annualized_sales.parquet \
	../input/acris_private_market_site_sale_events.parquet \
	../input/acris_private_market_site_sale_bbl_incidence.parquet \
	../input/mappluto_opportunity_lots_frozen.parquet

include ../../generic.make
