SHELL := bash
include ../../shell_functions.make

all: ../output/acris_direct_opportunity_deed_parties.parquet

../output/acris_direct_opportunity_deed_parties.parquet: stage_acris_direct_opportunity_deed_parties.R ../../_lib/source_pipeline_utils.R ../input/acris_direct_opportunity_deed_party_files.csv ../input/acris_direct_opportunity_deed_bbls.parquet | ../output
	$(R) $<

../input/acris_direct_opportunity_deed_party_files.csv: ../../fetch_acris_direct_opportunity_deed_parties/output/acris_direct_opportunity_deed_party_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_direct_opportunity_deed_bbls.parquet: ../../build_acris_direct_opportunity_deed_bbls/output/acris_direct_opportunity_deed_bbls.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/acris_direct_opportunity_deed_party_files.csv ../input/acris_direct_opportunity_deed_bbls.parquet

include ../../generic.make
