SHELL := bash
include ../../shell_functions.make

all: ../output/acris_opportunity_blocks.csv

../output/acris_opportunity_blocks.csv: build_acris_opportunity_block_universe.R ../input/mappluto_opportunity_lots_frozen.parquet | ../output
	$(R) $<

../input/mappluto_opportunity_lots_frozen.parquet: ../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" || ln -sf "../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" "$@"

link-inputs: ../input/mappluto_opportunity_lots_frozen.parquet

include ../../generic.make
