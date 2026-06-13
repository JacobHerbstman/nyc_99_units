SHELL := bash
include ../../shell_functions.make

all: ../output/acris_direct_deed_all_legals.parquet

../output/acris_direct_deed_all_legals.parquet: stage_acris_direct_deed_all_legals.R ../input/acris_direct_deed_all_legal_files.csv ../input/acris_direct_opportunity_deed_bbls.parquet ../input/mappluto_opportunity_lots_frozen.parquet | ../output
	$(R) $<

../input/acris_direct_deed_all_legal_files.csv: ../../fetch_acris_direct_deed_all_legals/output/acris_direct_deed_all_legal_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/acris_direct_opportunity_deed_bbls.parquet: ../../build_acris_direct_opportunity_deed_bbls/output/acris_direct_opportunity_deed_bbls.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_opportunity_lots_frozen.parquet: ../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/acris_direct_deed_all_legal_files.csv ../input/acris_direct_opportunity_deed_bbls.parquet ../input/mappluto_opportunity_lots_frozen.parquet

include ../../generic.make
