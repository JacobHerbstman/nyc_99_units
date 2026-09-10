include ../../shared/code/shell_functions.make

THRESHOLD_UNITS := 100

ifneq ($(filter command,$(origin THRESHOLD_UNITS)),)

$(error These fixed-name outputs use the settings recorded in this Makefile; edit those settings here so Make tracks the change)

endif

all: ../output/hpd_485x_registration_dob_links.csv ../report/hpd_485x_registration_dob_links.txt \
	../output/hpd_485x_registrations.parquet ../report/hpd_485x_registrations.txt

../output/hpd_485x_registration_dob_links.csv: link_hpd_485x_registrations.R Makefile \
	../output/hpd_485x_registrations.parquet ../input/dob_now_new_building_initial_filings.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $< $(THRESHOLD_UNITS)

../report/hpd_485x_registration_dob_links.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/hpd_485x_registration_dob_links.csv Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../report
	$(R) $< hpd_485x_registration_dob_links

../output/hpd_485x_registrations.parquet: stage_hpd_485x_registrations.R ../../shared/code/source_pipeline_utils.R \
	../input/hpd_485x_registration_files.csv Makefile ../input/hpd_485x_registrations.csv \
	../input/hpd_485x_registrations_metadata.json ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../output
	$(R) $<

../report/hpd_485x_registrations.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/hpd_485x_registrations.parquet Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../report
	$(R) $< hpd_485x_registrations

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hpd_485x_registration_files.csv: ../../fetch_hpd_485x_registrations/output/hpd_485x_registration_files.csv \
	| ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hpd_485x_registrations.csv: \
	../../fetch_hpd_485x_registrations/output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hpd_485x_registrations_metadata.json: \
	../../fetch_hpd_485x_registrations/output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json | \
	../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet

.PHONY: check-fetch_hpd_485x_registrations

check-fetch_hpd_485x_registrations:
	$(MAKE) -C ../../fetch_hpd_485x_registrations/code all ../output/hpd_485x_registration_files.csv \
	../output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv \
	../output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json

../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet: check-stage_dob_now_new_building_filings ;

../../fetch_hpd_485x_registrations/output/hpd_485x_registration_files.csv \
	../../fetch_hpd_485x_registrations/output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv \
	../../fetch_hpd_485x_registrations/output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json: check-fetch_hpd_485x_registrations ;

link-inputs: ../input/dob_now_new_building_initial_filings.parquet ../input/hpd_485x_registration_files.csv \
	../input/hpd_485x_registrations.csv ../input/hpd_485x_registrations_metadata.json

include ../../shared/code/generic.make
