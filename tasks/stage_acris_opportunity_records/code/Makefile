SHELL := bash
include ../../shell_functions.make

all: ../output/acris_opportunity_legals.parquet

../output/acris_opportunity_legals.parquet: stage_acris_opportunity_records.R ../input/acris_opportunity_record_files.csv | ../output
	$(R) $<

../input/acris_opportunity_record_files.csv: ../../fetch_acris_opportunity_records/output/acris_opportunity_record_files.csv | ../input
	@test "$$(readlink "$@")" = "../../fetch_acris_opportunity_records/output/acris_opportunity_record_files.csv" || ln -sf "../../fetch_acris_opportunity_records/output/acris_opportunity_record_files.csv" "$@"

link-inputs: ../input/acris_opportunity_record_files.csv

include ../../generic.make
