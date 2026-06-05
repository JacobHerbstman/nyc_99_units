SHELL := bash
include ../../shell_functions.make

all: ../output/opportunity_lot_quarter_panel.parquet

../output/opportunity_lot_quarter_panel.parquet: build_opportunity_lot_quarter_panel.R ../input/mappluto_opportunity_lots_frozen.parquet ../input/opportunity_sales_exact_bbl.parquet | ../output
	$(R) $<

../input/mappluto_opportunity_lots_frozen.parquet: ../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" || ln -sf "../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" "$@"

../input/opportunity_sales_exact_bbl.parquet: ../../build_opportunity_sales_exact_bbl/output/opportunity_sales_exact_bbl.parquet | ../input
	@test "$$(readlink "$@")" = "../../build_opportunity_sales_exact_bbl/output/opportunity_sales_exact_bbl.parquet" || ln -sf "../../build_opportunity_sales_exact_bbl/output/opportunity_sales_exact_bbl.parquet" "$@"

link-inputs: ../input/mappluto_opportunity_lots_frozen.parquet ../input/opportunity_sales_exact_bbl.parquet

include ../../generic.make
