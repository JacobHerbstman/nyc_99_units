include ../../shared/code/shell_functions.make

all: ../output/dob_now_new_building_filing_files.csv

include ../../shared/code/generic.make

../output/dob_now_new_building_filing_files.csv: source_files.csv Makefile \
	../output/dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026.csv \
	../output/dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026.csv \
	../../shared/code/copy_data.R ../../shared/code/write_data_report.R | $(OOPR)
	$(R) ../../shared/code/copy_data.R $< $@ file_role

../output/dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026.csv: \
	../../../data_raw/dob_now_build_job_filings/20260710/dob_now_new_building_initial_filings_2016_2026.csv \
	Makefile ../../shared/code/copy_data.R ../../shared/code/write_data_report.R | $(OOPR)
	printf '%s  %s\n' a0f179208477025e0f06d1f5a4b4fd67061d11ae0bd9c95fcfb06d4407b914cb $< | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@

../output/dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026.csv: \
	../../../data_raw/dob_now_build_job_filings/20260710/dob_now_new_building_amendments_2024_2026.csv Makefile \
	../../shared/code/copy_data.R ../../shared/code/write_data_report.R | $(OOPR)
	printf '%s  %s\n' 164fc244c6a1ae36bed7b9f5a7ca11015e410798bdf28e510323121f44fb1495 $< | shasum -a 256 -c -
	$(R) ../../shared/code/copy_data.R $< $@
