SHELL := bash
include ../../shell_functions.make

all: ../output/market_site_sale_events.parquet ../output/market_site_sale_event_bbl_incidence.parquet ../output/acris_deed_document_classified.parquet ../output/acris_document_cluster_candidates.parquet

../output/market_site_sale_events.parquet: build_acris_market_site_sale_universe.R party_classification_terms.csv ../input/acris_deed_master.parquet ../input/acris_direct_deed_all_legals.parquet ../input/acris_direct_opportunity_deed_parties.parquet ../input/mappluto_opportunity_lots_frozen.parquet | ../output
	$(R) $<

../output/market_site_sale_event_bbl_incidence.parquet: ../output/market_site_sale_events.parquet
	@test -s "$@"

../output/acris_deed_document_classified.parquet: ../output/market_site_sale_events.parquet
	@test -s "$@"

../output/acris_document_cluster_candidates.parquet: ../output/market_site_sale_events.parquet
	@test -s "$@"

../input/acris_deed_master.parquet: ../../stage_acris_deed_master/output/acris_deed_master.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_direct_deed_all_legals.parquet: ../../stage_acris_direct_deed_all_legals/output/acris_direct_deed_all_legals.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_direct_opportunity_deed_parties.parquet: ../../stage_acris_direct_opportunity_deed_parties/output/acris_direct_opportunity_deed_parties.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_opportunity_lots_frozen.parquet: ../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/acris_deed_master.parquet ../input/acris_direct_deed_all_legals.parquet ../input/acris_direct_opportunity_deed_parties.parquet ../input/mappluto_opportunity_lots_frozen.parquet

include ../../generic.make
