include ../../shared/code/shell_functions.make

all: ../output/hpd_485x_registration_dob_links.csv

include ../../shared/code/generic.make

../output/hpd_485x_registration_dob_links.csv: link_hpd_485x_registrations.R ../input/hpd_485x_registrations.csv \
	../input/dob_now_new_building_initial_filings.parquet Makefile | $(OOPR)
	$(R) $<

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@

../input/hpd_485x_registrations.csv: \
	../../fetch_hpd_485x_registrations/output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv | ../input
	ln -sf $< $@
