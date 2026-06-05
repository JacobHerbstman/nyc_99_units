SHELL := bash
include ../../shell_functions.make

all: ../output/acris_deed_master_files.csv

../output/acris_deed_master_files.csv: fetch_acris_deed_master.R ../input/source_catalog.csv | ../output
	$(R) $<

../input/source_catalog.csv: ../../source_registry/code/source_catalog.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/source_catalog.csv

include ../../generic.make
