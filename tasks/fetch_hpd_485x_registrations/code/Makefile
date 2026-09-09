include ../../shared/code/shell_functions.make

all: ../output/hpd_485x_registration_files.csv \
	../report/hpd_485x_registration_files.txt \
	../report/hpd_485x_registrations_20260820_hpd_485x_registrations.txt

../output/hpd_485x_registration_files.csv: source_files.csv Makefile \
	../output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv \
	../output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json | ../output
	cp $< $@

../output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv: ../../../data_raw/hpd_485x_registrations/20260820/hpd_485x_registrations.csv Makefile | ../output
	printf '%s  %s\n' 9e7fa1d2aeb6774cf65d7bcff7f3aef8dee4e51cf99a0a9dd3f922225f70a45d $< | shasum -a 256 -c -
	cp $< $@

../output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json: ../../../data_raw/hpd_485x_registrations/20260820/hpd_485x_registrations_metadata.json Makefile | ../output
	printf '%s  %s\n' 4786a790a9f9e245646ea041d4fefac457e5bb0fc656a65abd9402ef5c4eb2e1 $< | shasum -a 256 -c -
	cp $< $@




../report/hpd_485x_registration_files.txt: report_data.R ../../shared/code/write_data_report.R ../output/hpd_485x_registration_files.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< hpd_485x_registration_files

../report/hpd_485x_registrations_20260820_hpd_485x_registrations.txt: report_data.R ../../shared/code/write_data_report.R ../output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< hpd_485x_registrations_20260820_hpd_485x_registrations


include ../../shared/code/generic.make
