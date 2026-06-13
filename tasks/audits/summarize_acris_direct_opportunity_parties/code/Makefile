SHELL := bash
include ../../../shell_functions.make

all: ../output/acris_direct_opportunity_party_coverage_by_borough.csv \
	../output/acris_direct_opportunity_party_type_counts.csv \
	../output/acris_direct_opportunity_top_party_names.csv

../output/acris_direct_opportunity_party_coverage_by_borough.csv: summarize_acris_direct_opportunity_parties.R ../../../_lib/source_pipeline_utils.R ../input/acris_direct_opportunity_deed_bbls.parquet ../input/acris_direct_opportunity_deed_parties.parquet | ../output
	$(R) $<

../output/acris_direct_opportunity_party_type_counts.csv ../output/acris_direct_opportunity_top_party_names.csv: ../output/acris_direct_opportunity_party_coverage_by_borough.csv
	@test -s "$@"

../input/acris_direct_opportunity_deed_bbls.parquet: ../../../build_acris_direct_opportunity_deed_bbls/output/acris_direct_opportunity_deed_bbls.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_direct_opportunity_deed_parties.parquet: ../../../stage_acris_direct_opportunity_deed_parties/output/acris_direct_opportunity_deed_parties.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/acris_direct_opportunity_deed_bbls.parquet ../input/acris_direct_opportunity_deed_parties.parquet

include ../../generic.make
