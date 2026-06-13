SHELL := bash
include ../../shell_functions.make

all: ../output/acris_direct_opportunity_legals.parquet

../output/acris_direct_opportunity_legals.parquet: stage_acris_direct_opportunity_legals.R ../input/acris_direct_opportunity_legal_files.csv ../input/mappluto_opportunity_lots_frozen.parquet | ../output
	$(R) $<

../input/acris_direct_opportunity_legal_files.csv: ../../fetch_acris_direct_opportunity_legals/output/acris_direct_opportunity_legal_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_opportunity_lots_frozen.parquet: ../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/acris_direct_opportunity_legal_files.csv ../input/mappluto_opportunity_lots_frozen.parquet

include ../../generic.make
