SHELL := bash
include ../../shell_functions.make

all: ../output/acris_direct_opportunity_deed_bbls.parquet

../output/acris_direct_opportunity_deed_bbls.parquet: build_acris_direct_opportunity_deed_bbls.R ../../_lib/source_pipeline_utils.R ../input/acris_direct_opportunity_legals.parquet ../input/acris_deed_master.parquet | ../output
	$(R) $<

../input/acris_direct_opportunity_legals.parquet: ../../stage_acris_direct_opportunity_legals/output/acris_direct_opportunity_legals.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_deed_master.parquet: ../../stage_acris_deed_master/output/acris_deed_master.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/acris_direct_opportunity_legals.parquet ../input/acris_deed_master.parquet

include ../../generic.make
