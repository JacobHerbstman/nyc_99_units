include ../../shared/code/shell_functions.make

FILES := ../output/dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026.csv \
	../output/dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026.csv

all: $(FILES)

include ../../shared/code/generic.make

# Captures are copied only when missing, and published only if their bytes match
# checksums.sha256.
../output/dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026.csv: \
	../../../data_raw/dob_now_build_job_filings/20260710/dob_now_new_building_initial_filings_2016_2026.csv \
	../../shared/code/copy_data.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

../output/dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026.csv: \
	../../../data_raw/dob_now_build_job_filings/20260710/dob_now_new_building_amendments_2024_2026.csv \
	../../shared/code/copy_data.R | $(OOPR)
	awk '$$2 == "$@" { print $$1 "  $<" }' checksums.sha256 | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@
