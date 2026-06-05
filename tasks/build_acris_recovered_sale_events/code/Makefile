SHELL := bash
include ../../shell_functions.make

all: ../output/acris_recovered_sale_events.parquet

../output/acris_recovered_sale_events.parquet: build_acris_recovered_sale_events.R ../input/acris_dof_deed_candidate_links.parquet ../input/acris_opportunity_legals.parquet ../input/mappluto_opportunity_lots_frozen.parquet | ../output
	$(R) $<

../input/acris_dof_deed_candidate_links.parquet: ../../build_acris_dof_deed_candidates/output/acris_dof_deed_candidate_links.parquet | ../input
	@test "$$(readlink "$@")" = "../../build_acris_dof_deed_candidates/output/acris_dof_deed_candidate_links.parquet" || ln -sf "../../build_acris_dof_deed_candidates/output/acris_dof_deed_candidate_links.parquet" "$@"

../input/acris_opportunity_legals.parquet: ../../stage_acris_opportunity_records/output/acris_opportunity_legals.parquet | ../input
	@test "$$(readlink "$@")" = "../../stage_acris_opportunity_records/output/acris_opportunity_legals.parquet" || ln -sf "../../stage_acris_opportunity_records/output/acris_opportunity_legals.parquet" "$@"

../input/mappluto_opportunity_lots_frozen.parquet: ../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" || ln -sf "../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet" "$@"

link-inputs: ../input/acris_dof_deed_candidate_links.parquet ../input/acris_opportunity_legals.parquet ../input/mappluto_opportunity_lots_frozen.parquet

include ../../generic.make
