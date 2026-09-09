include ../../shared/code/shell_functions.make

THRESHOLD_UNITS := 100

ifneq ($(filter command,$(origin THRESHOLD_UNITS)),)
$(error These fixed-name outputs use the settings recorded in this Makefile; edit those settings here so Make tracks the change)
endif

all: ../output/hpd_485x_registration_dob_links.csv \
	../report/hpd_485x_registration_dob_links.txt

../output/hpd_485x_registration_dob_links.csv: link_hpd_485x_registrations.R Makefile \
	../input/hpd_485x_registrations.parquet ../input/dob_now_new_building_initial_filings.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $< $(THRESHOLD_UNITS)


../report/hpd_485x_registration_dob_links.txt: report_data.R ../../shared/code/write_data_report.R ../output/hpd_485x_registration_dob_links.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< hpd_485x_registration_dob_links


../input/hpd_485x_registrations.parquet: ../../stage_hpd_485x_registrations/output/hpd_485x_registrations.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hpd_485x_registrations.parquet \
	../input/dob_now_new_building_initial_filings.parquet

../../stage_hpd_485x_registrations/output/hpd_485x_registrations.parquet: check-stage_hpd_485x_registrations ;

.PHONY: check-stage_hpd_485x_registrations

check-stage_hpd_485x_registrations:
	$(MAKE) -C ../../stage_hpd_485x_registrations/code all ../output/hpd_485x_registrations.parquet

../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet: check-stage_dob_now_new_building_filings ;

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet

include ../../shared/code/generic.make
