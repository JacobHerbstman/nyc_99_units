SHELL := bash
include ../../shell_functions.make

all: ../output/dob_now_new_building_filing_files.csv

../output/dob_now_new_building_filing_files.csv: fetch_dob_now_new_building_filings.R ../input/source_catalog.csv | ../output
	$(R) $<

../input/source_catalog.csv: ../../source_registry/code/source_catalog.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/source_catalog.csv

include ../../generic.make
