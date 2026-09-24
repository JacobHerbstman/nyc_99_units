include ../../shared/code/shell_functions.make

all: ../output/dob_bis_job_filings_20260923_nb_initial_filings.csv

include ../../shared/code/generic.make

# checksums.sha256 records the published bytes; the capture is copied only when missing.
../output/dob_bis_job_filings_20260923_nb_initial_filings.csv: \
	../../../data_raw/dob_bis_job_filings/2026-09-23/nb_initial_filings.csv \
	../../shared/code/copy_data.R ../../shared/code/write_data_report.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

# The Open Data API is mutable: query it only when the dated capture is missing.
../../../data_raw/dob_bis_job_filings/2026-09-23/nb_initial_filings.csv:
	mkdir -p $(@D)
	python3 download_bis.py $@
