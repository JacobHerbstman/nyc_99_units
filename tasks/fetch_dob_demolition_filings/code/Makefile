include ../../shared/code/shell_functions.make

RAW := ../../../data_raw/dob_demolition_filings/2026-10-01
SYSTEMS := bis dob_now

all: $(SYSTEMS:%=../output/dob_demolition_filings_20261001_%_demolitions.csv)

include ../../shared/code/generic.make

# checksums.sha256 records the published bytes; the capture is copied only when missing.
../output/dob_demolition_filings_20261001_%_demolitions.csv: $(RAW)/%_demolitions.csv ../../shared/code/copy_data.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

# The Open Data API is mutable: query it only when the dated capture is missing,
# and save the capture only if its bytes match the recorded checksum.
$(RAW)/%_demolitions.csv: | ../temp
	python3 download_demolitions.py $* ../temp/$*_demolitions.csv
	awk '$$2 == "../output/dob_demolition_filings_20261001_$*_demolitions.csv" { print $$1 "  ../temp/$*_demolitions.csv" }' \
		checksums.sha256 | shasum -a 256 -c -
	mkdir -p $(@D)
	mv ../temp/$*_demolitions_manifest.csv $(@D)/$*_demolitions_manifest.csv
	mv ../temp/$*_demolitions.csv $@
