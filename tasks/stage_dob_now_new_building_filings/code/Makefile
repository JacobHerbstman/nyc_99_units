SHELL := bash
include ../../shell_functions.make

all: ../output/dob_now_new_building_filings.parquet \
	../output/dob_now_new_building_initial_filings.parquet

../output/dob_now_new_building_filings.parquet: stage_dob_now_new_building_filings.R ../input/dob_now_new_building_filing_files.csv | ../output
	$(R) $<

../output/dob_now_new_building_initial_filings.parquet: ../output/dob_now_new_building_filings.parquet
	@test -s "$@"

../input/dob_now_new_building_filing_files.csv: ../../fetch_dob_now_new_building_filings/output/dob_now_new_building_filing_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dob_now_new_building_filing_files.csv

include ../../generic.make
