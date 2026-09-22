include ../../shared/code/shell_functions.make

FILES := ../output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv \
	../output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json

all: ../output/hpd_485x_registration_files.csv

include ../../shared/code/generic.make

# checksums.sha256 records the bytes of every published file. Captures are
# copied only when missing; editing the ledger re-verifies all of them here.
../output/hpd_485x_registration_files.csv: source_files.csv checksums.sha256 $(FILES) \
	../../shared/code/copy_data.R ../../shared/code/write_data_report.R | $(OOPR)
	shasum -a 256 --quiet -c checksums.sha256
	$(R) ../../shared/code/copy_data.R $< $@ file_role

../output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv: \
	../../../data_raw/hpd_485x_registrations/20260820/hpd_485x_registrations.csv \
	../../shared/code/copy_data.R ../../shared/code/write_data_report.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

../output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json: \
	../../../data_raw/hpd_485x_registrations/20260820/hpd_485x_registrations_metadata.json | ../output
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@
