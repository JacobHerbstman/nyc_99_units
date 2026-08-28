SHELL := bash
include ../../shell_functions.make

THRESHOLD_UNITS := 100

all: ../output/hpd_485x_registration_dob_links.csv

../output/hpd_485x_registration_dob_links.csv: link_hpd_485x_registrations.R \
	../input/hpd_485x_registrations.parquet \
	../input/dob_now_new_building_initial_filings.parquet | ../output
	$(R) $< $(THRESHOLD_UNITS)

../input/hpd_485x_registrations.parquet: ../../stage_hpd_485x_registrations/output/hpd_485x_registrations.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hpd_485x_registrations.parquet \
	../input/dob_now_new_building_initial_filings.parquet

include ../../generic.make
