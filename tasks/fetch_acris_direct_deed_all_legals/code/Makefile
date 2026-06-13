SHELL := bash
include ../../shell_functions.make

all: ../output/acris_direct_deed_all_legal_files.csv

../output/acris_direct_deed_all_legal_files.csv: fetch_acris_direct_deed_all_legals.R ../input/acris_direct_opportunity_deed_bbls.parquet ../input/source_catalog.csv | ../output
	$(R) $<

../input/acris_direct_opportunity_deed_bbls.parquet: ../../build_acris_direct_opportunity_deed_bbls/output/acris_direct_opportunity_deed_bbls.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/source_catalog.csv: ../../source_registry/code/source_catalog.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/acris_direct_opportunity_deed_bbls.parquet ../input/source_catalog.csv

include ../../generic.make
