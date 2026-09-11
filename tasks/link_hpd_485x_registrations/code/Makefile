include ../../shared/code/shell_functions.make
THRESHOLD_UNITS := 100

ifneq ($(filter command,$(origin THRESHOLD_UNITS)),)
$(error These fixed-name outputs use the settings recorded in this Makefile; edit those settings here so Make tracks the change)
endif

all: ../report/hpd_485x_registrations.txt ../output/hpd_485x_registrations.parquet \
	../report/hpd_485x_registration_dob_links.txt ../output/hpd_485x_registration_dob_links.csv

../output/hpd_485x_registration_dob_links.csv ../report/hpd_485x_registration_dob_links.txt: \
	link_hpd_485x_registrations.R Makefile ../output/hpd_485x_registrations.parquet \
	../input/dob_now_new_building_initial_filings.parquet ../../shared/code/write_data_report.R | ../output ../report
	$(R) $< $(THRESHOLD_UNITS)

../output/hpd_485x_registrations.parquet ../report/hpd_485x_registrations.txt: stage_hpd_485x_registrations.R \
	../../shared/code/source_pipeline_utils.R ../input/hpd_485x_registration_files.csv Makefile \
	../input/hpd_485x_registrations.csv ../input/hpd_485x_registrations_metadata.json \
	../../shared/code/write_data_report.R | ../output ../report
	$(R) $<

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@

../input/hpd_485x_registration_files.csv: ../../fetch_hpd_485x_registrations/output/hpd_485x_registration_files.csv | \
	../input
	ln -sf $< $@

../input/hpd_485x_registrations.csv: \
	../../fetch_hpd_485x_registrations/output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv | ../input
	ln -sf $< $@

../input/hpd_485x_registrations_metadata.json: \
	../../fetch_hpd_485x_registrations/output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json | \
	../input
	ln -sf $< $@

link-inputs: ../input/dob_now_new_building_initial_filings.parquet ../input/hpd_485x_registration_files.csv \
	../input/hpd_485x_registrations.csv ../input/hpd_485x_registrations_metadata.json

include ../../shared/code/generic.make
