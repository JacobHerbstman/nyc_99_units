SHELL := bash
include ../../shell_functions.make

MAX_KEY_PRODUCT := 2500

all: ../output/acris_dof_deed_candidate_links.parquet

../output/acris_dof_deed_candidate_links.parquet: build_acris_dof_deed_candidates.R ../input/acris_opportunity_sale_seeds.parquet ../input/acris_deed_master.parquet | ../output
	$(R) $< $(MAX_KEY_PRODUCT)

../input/acris_opportunity_sale_seeds.parquet: ../../build_acris_opportunity_sale_seeds/output/acris_opportunity_sale_seeds.parquet | ../input
	@test "$$(readlink "$@")" = "../../build_acris_opportunity_sale_seeds/output/acris_opportunity_sale_seeds.parquet" || ln -sf "../../build_acris_opportunity_sale_seeds/output/acris_opportunity_sale_seeds.parquet" "$@"

../input/acris_deed_master.parquet: ../../stage_acris_deed_master/output/acris_deed_master.parquet | ../input
	@test "$$(readlink "$@")" = "../../stage_acris_deed_master/output/acris_deed_master.parquet" || ln -sf "../../stage_acris_deed_master/output/acris_deed_master.parquet" "$@"

link-inputs: ../input/acris_opportunity_sale_seeds.parquet ../input/acris_deed_master.parquet

include ../../generic.make
