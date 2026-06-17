SHELL := bash
include ../../shell_functions.make

all: ../output/acris_private_market_site_sale_events.parquet ../output/acris_private_market_site_sale_bbl_incidence.parquet

../output/acris_private_market_site_sale_events.parquet: build_acris_private_market_site_sales.R ../input/acris_site_events.parquet ../input/acris_site_event_bbl_incidence.parquet ../input/mappluto_opportunity_lots_frozen.parquet | ../output
	$(R) $<

../output/acris_private_market_site_sale_bbl_incidence.parquet: ../output/acris_private_market_site_sale_events.parquet

../input/acris_site_events.parquet: ../../build_acris_site_events/output/acris_site_events.parquet | ../input
	@test "$$(readlink "$@")" = "../../build_acris_site_events/output/acris_site_events.parquet" || ln -sf "../../build_acris_site_events/output/acris_site_events.parquet" "$@"

../input/acris_site_event_bbl_incidence.parquet: ../../build_acris_site_events/output/acris_site_event_bbl_incidence.parquet | ../input
	@test "$$(readlink "$@")" = "../../build_acris_site_events/output/acris_site_event_bbl_incidence.parquet" || ln -sf "../../build_acris_site_events/output/acris_site_event_bbl_incidence.parquet" "$@"

../input/mappluto_opportunity_lots_frozen.parquet: ../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" || ln -sf "../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" "$@"

link-inputs: ../input/acris_site_events.parquet ../input/acris_site_event_bbl_incidence.parquet ../input/mappluto_opportunity_lots_frozen.parquet

include ../../generic.make
