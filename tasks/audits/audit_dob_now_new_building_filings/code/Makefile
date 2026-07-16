SHELL := bash

all: ../output/dob_now_new_building_initial_filings_qc.csv

../output/dob_now_new_building_initial_filings_qc.csv: audit_dob_now_new_building_filings.R ../../../_lib/source_pipeline_utils.R ../input/dob_now_new_building_filings.parquet ../input/dob_now_new_building_initial_filings.parquet | ../output
	$(R) $<

../input/dob_now_new_building_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dob_now_new_building_filings.parquet \
	../input/dob_now_new_building_initial_filings.parquet

include ../../generic.make
