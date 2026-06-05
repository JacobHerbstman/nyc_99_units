SHELL := bash
include ../../shell_functions.make

all: ../output/acris_deed_master.parquet

../output/acris_deed_master.parquet: stage_acris_deed_master.R ../input/acris_deed_master_files.csv | ../output
	$(R) $<

../input/acris_deed_master_files.csv: ../../fetch_acris_deed_master/output/acris_deed_master_files.csv | ../input
	@test "$$(readlink "$@")" = "../../fetch_acris_deed_master/output/acris_deed_master_files.csv" || ln -sf "../../fetch_acris_deed_master/output/acris_deed_master_files.csv" "$@"

link-inputs: ../input/acris_deed_master_files.csv

include ../../generic.make
