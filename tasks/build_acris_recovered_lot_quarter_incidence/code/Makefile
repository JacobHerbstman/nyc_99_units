SHELL := bash
include ../../shell_functions.make

all: ../output/acris_recovered_sale_lot_quarter_incidence.parquet

../output/acris_recovered_sale_lot_quarter_incidence.parquet: build_acris_recovered_lot_quarter_incidence.R ../input/acris_recovered_sale_events.parquet ../input/mappluto_opportunity_lots_frozen.parquet | ../output
	$(R) $<

../input/acris_recovered_sale_events.parquet: ../../build_acris_recovered_sale_events/output/acris_recovered_sale_events.parquet | ../input
	@test "$$(readlink "$@")" = "../../build_acris_recovered_sale_events/output/acris_recovered_sale_events.parquet" || ln -sf "../../build_acris_recovered_sale_events/output/acris_recovered_sale_events.parquet" "$@"

../input/mappluto_opportunity_lots_frozen.parquet: ../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" || ln -sf "../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" "$@"

link-inputs: ../input/acris_recovered_sale_events.parquet ../input/mappluto_opportunity_lots_frozen.parquet

include ../../generic.make
