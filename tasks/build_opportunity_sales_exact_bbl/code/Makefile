SHELL := bash
include ../../shell_functions.make

all: ../output/opportunity_sales_exact_bbl.parquet

../output/opportunity_sales_exact_bbl.parquet: build_opportunity_sales_exact_bbl.R ../input/mappluto_opportunity_lots_frozen.parquet ../input/dof_annualized_sales.parquet | ../output
	$(R) $<

../input/mappluto_opportunity_lots_frozen.parquet: ../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" || ln -sf "../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" "$@"

../input/dof_annualized_sales.parquet: ../../stage_dof_annualized_sales/output/dof_annualized_sales.parquet | ../input
	@test "$$(readlink "$@")" = "../../stage_dof_annualized_sales/output/dof_annualized_sales.parquet" || ln -sf "../../stage_dof_annualized_sales/output/dof_annualized_sales.parquet" "$@"

link-inputs: ../input/mappluto_opportunity_lots_frozen.parquet ../input/dof_annualized_sales.parquet

include ../../generic.make
