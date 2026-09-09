include ../../shared/code/shell_functions.make

all: ../output/hpd_485x_registrations.parquet \
	../report/hpd_485x_registrations.txt

../output/hpd_485x_registrations.parquet: stage_hpd_485x_registrations.R \
	../../shared/code/source_pipeline_utils.R ../input/hpd_485x_registration_files.csv Makefile \
	../input/hpd_485x_registrations.csv ../input/hpd_485x_registrations_metadata.json \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<


../report/hpd_485x_registrations.txt: report_data.R ../../shared/code/write_data_report.R ../output/hpd_485x_registrations.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< hpd_485x_registrations


../input/hpd_485x_registration_files.csv: ../../fetch_hpd_485x_registrations/output/hpd_485x_registration_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/hpd_485x_registration_files.csv

../input/hpd_485x_registrations.csv: ../../fetch_hpd_485x_registrations/output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hpd_485x_registrations_metadata.json: ../../fetch_hpd_485x_registrations/output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../fetch_hpd_485x_registrations/output/hpd_485x_registration_files.csv \
	../../fetch_hpd_485x_registrations/output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv \
	../../fetch_hpd_485x_registrations/output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json: check-fetch_hpd_485x_registrations ;

.PHONY: check-fetch_hpd_485x_registrations

check-fetch_hpd_485x_registrations:
	$(MAKE) -C ../../fetch_hpd_485x_registrations/code all ../output/hpd_485x_registration_files.csv ../output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv ../output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json

include ../../shared/code/generic.make
