SHELL := bash
include ../../shell_functions.make

all: ../output/acris_direct_opportunity_legal_files.csv

../output/acris_direct_opportunity_legal_files.csv: fetch_acris_direct_opportunity_legals.R ../input/mappluto_opportunity_lots_frozen.parquet ../input/source_catalog.csv | ../output
	$(R) $<

../input/mappluto_opportunity_lots_frozen.parquet: ../../build_frozen_opportunity_lots/output/mappluto_opportunity_lots_frozen.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/source_catalog.csv: ../../source_registry/code/source_catalog.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/mappluto_opportunity_lots_frozen.parquet ../input/source_catalog.csv

include ../../generic.make
