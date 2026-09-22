include ../../shared/code/shell_functions.make

FILES := ../output/dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026.csv \
	../output/dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026.csv

all: ../output/dob_now_new_building_filing_files.csv

include ../../shared/code/generic.make

# checksums.sha256 records the bytes of every published file. Captures are
# copied only when missing; editing the ledger re-verifies all of them here.
../output/dob_now_new_building_filing_files.csv: source_files.csv checksums.sha256 $(FILES) \
	../../shared/code/copy_data.R ../../shared/code/write_data_report.R | $(OOPR)
	shasum -a 256 --quiet -c checksums.sha256
	$(R) ../../shared/code/copy_data.R $< $@ file_role

../output/dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026.csv: \
	../../../data_raw/dob_now_build_job_filings/20260710/dob_now_new_building_initial_filings_2016_2026.csv \
	../../shared/code/copy_data.R ../../shared/code/write_data_report.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

../output/dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026.csv: \
	../../../data_raw/dob_now_build_job_filings/20260710/dob_now_new_building_amendments_2024_2026.csv \
	../../shared/code/copy_data.R ../../shared/code/write_data_report.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@
