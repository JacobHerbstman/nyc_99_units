SHELL := bash
include ../../shell_functions.make

all: ../output/acris_opportunity_sale_seeds.parquet

../output/acris_opportunity_sale_seeds.parquet: build_acris_opportunity_sale_seeds.R ../input/mappluto_opportunity_lots_frozen.parquet ../input/acris_opportunity_blocks.csv ../input/dof_annualized_sales.parquet | ../output
	$(R) $<

../input/mappluto_opportunity_lots_frozen.parquet: ../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" || ln -sf "../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" "$@"

../input/acris_opportunity_blocks.csv: ../../build_acris_opportunity_block_universe/output/acris_opportunity_blocks.csv | ../input
	@test "$$(readlink "$@")" = "../../build_acris_opportunity_block_universe/output/acris_opportunity_blocks.csv" || ln -sf "../../build_acris_opportunity_block_universe/output/acris_opportunity_blocks.csv" "$@"

../input/dof_annualized_sales.parquet: ../../stage_dof_annualized_sales/output/dof_annualized_sales.parquet | ../input
	@test "$$(readlink "$@")" = "../../stage_dof_annualized_sales/output/dof_annualized_sales.parquet" || ln -sf "../../stage_dof_annualized_sales/output/dof_annualized_sales.parquet" "$@"

link-inputs: ../input/mappluto_opportunity_lots_frozen.parquet ../input/acris_opportunity_blocks.csv ../input/dof_annualized_sales.parquet

include ../../generic.make
