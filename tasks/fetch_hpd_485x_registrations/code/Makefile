SHELL := bash
include ../../shell_functions.make

all: ../output/hpd_485x_registration_files.csv

../output/hpd_485x_registration_files.csv: fetch_hpd_485x_registrations.R ../../_lib/source_pipeline_utils.R ../input/source_catalog.csv | ../output
	$(R) $<

../input/source_catalog.csv: ../../source_registry/code/source_catalog.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/source_catalog.csv

include ../../generic.make
