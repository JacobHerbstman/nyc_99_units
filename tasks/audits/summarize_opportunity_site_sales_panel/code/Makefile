SHELL := bash
include ../../../shell_functions.make

all: ../output/opportunity_lot_counts.csv \
	../output/opportunity_panel_hard_checks.csv \
	../output/opportunity_capacity_thresholds.csv \
	../output/opportunity_sales_linkage_summary.csv \
	../output/opportunity_sales_price_distribution.csv \
	../output/opportunity_acris_site_sale_linkage_summary.csv \
	../output/opportunity_acris_site_sale_price_distribution.csv \
	../output/opportunity_exact_match_bias_by_capacity_quartile.csv

../output/opportunity_lot_counts.csv: summarize_opportunity_site_sales_panel.R ../input/mappluto_opportunity_lots_frozen.parquet ../input/opportunity_sales_exact_bbl.parquet ../input/opportunity_lot_quarter_panel.parquet ../input/acris_private_market_site_sale_bbl_incidence.parquet ../input/dof_annualized_sales.parquet | ../output
	$(R) $<

../output/opportunity_panel_hard_checks.csv ../output/opportunity_capacity_thresholds.csv ../output/opportunity_sales_linkage_summary.csv ../output/opportunity_sales_price_distribution.csv ../output/opportunity_acris_site_sale_linkage_summary.csv ../output/opportunity_acris_site_sale_price_distribution.csv ../output/opportunity_exact_match_bias_by_capacity_quartile.csv: ../output/opportunity_lot_counts.csv
	@test -s "$@"

../input/mappluto_opportunity_lots_frozen.parquet: ../../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" || ln -sf "../../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" "$@"

../input/opportunity_sales_exact_bbl.parquet: ../../../build_opportunity_sales_exact_bbl/output/opportunity_sales_exact_bbl.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_opportunity_sales_exact_bbl/output/opportunity_sales_exact_bbl.parquet" || ln -sf "../../../build_opportunity_sales_exact_bbl/output/opportunity_sales_exact_bbl.parquet" "$@"

../input/opportunity_lot_quarter_panel.parquet: ../../../build_opportunity_lot_quarter_panel/output/opportunity_lot_quarter_panel.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_opportunity_lot_quarter_panel/output/opportunity_lot_quarter_panel.parquet" || ln -sf "../../../build_opportunity_lot_quarter_panel/output/opportunity_lot_quarter_panel.parquet" "$@"

../input/acris_private_market_site_sale_bbl_incidence.parquet: ../../../build_acris_private_market_site_sales/output/acris_private_market_site_sale_bbl_incidence.parquet | ../input
	@test "$$(readlink "$@")" = "../../../build_acris_private_market_site_sales/output/acris_private_market_site_sale_bbl_incidence.parquet" || ln -sf "../../../build_acris_private_market_site_sales/output/acris_private_market_site_sale_bbl_incidence.parquet" "$@"

../input/dof_annualized_sales.parquet: ../../../stage_dof_annualized_sales/output/dof_annualized_sales.parquet | ../input
	@test "$$(readlink "$@")" = "../../../stage_dof_annualized_sales/output/dof_annualized_sales.parquet" || ln -sf "../../../stage_dof_annualized_sales/output/dof_annualized_sales.parquet" "$@"

link-inputs: ../input/mappluto_opportunity_lots_frozen.parquet ../input/opportunity_sales_exact_bbl.parquet ../input/opportunity_lot_quarter_panel.parquet ../input/acris_private_market_site_sale_bbl_incidence.parquet ../input/dof_annualized_sales.parquet

include ../../generic.make
