include ../../shared/code/shell_functions.make

all: ../output/hpd_485x_registration_files.csv

include ../../shared/code/generic.make

../output/hpd_485x_registration_files.csv: source_files.csv Makefile \
	../output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv \
	../output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json ../../shared/code/copy_data.R \
	../../shared/code/write_data_report.R | $(OOPR)
	$(R) ../../shared/code/copy_data.R $< $@ file_role

../output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv: \
	../../../data_raw/hpd_485x_registrations/20260820/hpd_485x_registrations.csv Makefile \
	../../shared/code/copy_data.R ../../shared/code/write_data_report.R | $(OOPR)
	printf '%s  %s\n' 9e7fa1d2aeb6774cf65d7bcff7f3aef8dee4e51cf99a0a9dd3f922225f70a45d $< | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

../output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json: \
	../../../data_raw/hpd_485x_registrations/20260820/hpd_485x_registrations_metadata.json Makefile | ../output
	printf '%s  %s\n' 4786a790a9f9e245646ea041d4fefac457e5bb0fc656a65abd9402ef5c4eb2e1 $< | shasum -a 256 -c -
	cp $< $@
