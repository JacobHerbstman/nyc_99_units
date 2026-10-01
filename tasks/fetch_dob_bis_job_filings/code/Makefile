include ../../shared/code/shell_functions.make

all: ../output/dob_bis_job_filings_20260923_nb_initial_filings.csv

include ../../shared/code/generic.make

# checksums.sha256 records the published bytes; the capture is copied only when missing.
../output/dob_bis_job_filings_20260923_nb_initial_filings.csv: \
	../../../data_raw/dob_bis_job_filings/2026-09-23/nb_initial_filings.csv ../../shared/code/copy_data.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

# The Open Data API is mutable: query it only when the dated capture is missing,
# and save the capture only if its bytes match the recorded checksum.
../../../data_raw/dob_bis_job_filings/2026-09-23/nb_initial_filings.csv: | ../temp
	python3 download_bis.py ../temp/nb_initial_filings.csv
	awk '$$2 == "../output/dob_bis_job_filings_20260923_nb_initial_filings.csv" { print $$1 "  ../temp/nb_initial_filings.csv" }' \
		checksums.sha256 | shasum -a 256 -c -
	mkdir -p $(@D)
	mv ../temp/manifest.csv $(@D)/manifest.csv
	mv ../temp/nb_initial_filings.csv $@
