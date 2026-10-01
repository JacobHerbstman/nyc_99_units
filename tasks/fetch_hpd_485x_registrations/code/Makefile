include ../../shared/code/shell_functions.make

FILES := ../output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv \
	../output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json

all: $(FILES)

include ../../shared/code/generic.make

# Captures are copied only when missing, and published only if their bytes match
# checksums.sha256.
../output/hpd_485x_registrations_20260820_hpd_485x_registrations.csv: \
	../../../data_raw/hpd_485x_registrations/20260820/hpd_485x_registrations.csv \
	../../shared/code/copy_data.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

../output/hpd_485x_registrations_20260820_hpd_485x_registrations_metadata.json: \
	../../../data_raw/hpd_485x_registrations/20260820/hpd_485x_registrations_metadata.json | ../output
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	cp $< $@
