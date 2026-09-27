include ../../shared/code/shell_functions.make

RAW := ../../../data_raw/dob_permits/2026-09-27

all: ../output/dob_permit_issuance_20260927_nb_permits.csv \
	../output/dob_now_approved_permits_20260927_general_construction.csv

include ../../shared/code/generic.make

# checksums.sha256 records the published bytes; each capture is copied only when missing.
../output/dob_permit_issuance_20260927_nb_permits.csv: $(RAW)/bis_nb_permits.csv \
	../../shared/code/copy_data.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

../output/dob_now_approved_permits_20260927_general_construction.csv: $(RAW)/now_general_construction_permits.csv \
	../../shared/code/copy_data.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

# The Open Data API is mutable: query it only when the dated capture is missing,
# and save the capture only if its bytes match the recorded checksum.
$(RAW)/bis_nb_permits.csv: | ../temp
	python3 download_permits.py bis_nb ../temp/bis_nb_permits.csv
	awk '$$2 == "../output/dob_permit_issuance_20260927_nb_permits.csv" { print $$1 "  ../temp/bis_nb_permits.csv" }' \
		checksums.sha256 | shasum -a 256 -c -
	mkdir -p $(@D)
	mv ../temp/bis_nb_permits_manifest.csv $(@D)/bis_nb_permits_manifest.csv
	mv ../temp/bis_nb_permits.csv $@

$(RAW)/now_general_construction_permits.csv: | ../temp
	python3 download_permits.py now_gc ../temp/now_general_construction_permits.csv
	awk '$$2 == "../output/dob_now_approved_permits_20260927_general_construction.csv" { print $$1 "  ../temp/now_general_construction_permits.csv" }' \
		checksums.sha256 | shasum -a 256 -c -
	mkdir -p $(@D)
	mv ../temp/now_general_construction_permits_manifest.csv $(@D)/now_general_construction_permits_manifest.csv
	mv ../temp/now_general_construction_permits.csv $@
