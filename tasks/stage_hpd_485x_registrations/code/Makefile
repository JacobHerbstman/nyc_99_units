SHELL := bash
include ../../shell_functions.make

all: ../output/hpd_485x_registrations.parquet

../output/hpd_485x_registrations.parquet: stage_hpd_485x_registrations.R ../../_lib/source_pipeline_utils.R ../input/hpd_485x_registration_files.csv | ../output
	$(R) $<

../input/hpd_485x_registration_files.csv: ../../fetch_hpd_485x_registrations/output/hpd_485x_registration_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hpd_485x_registration_files.csv

include ../../generic.make
