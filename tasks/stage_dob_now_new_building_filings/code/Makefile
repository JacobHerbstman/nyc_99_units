include ../../shared/code/shell_functions.make

all: ../output/dob_now_new_building_filings.parquet ../output/dob_now_new_building_initial_filings.parquet \
	../report/dob_now_new_building_filings.txt ../report/dob_now_new_building_initial_filings.txt

../output/dob_now_new_building_initial_filings.parquet ../output/dob_now_new_building_filings.parquet \
	../report/dob_now_new_building_filings.txt ../report/dob_now_new_building_initial_filings.txt: \
	stage_dob_now_new_building_filings.R ../../shared/code/source_pipeline_utils.R \
	../input/dob_now_new_building_filing_files.csv Makefile ../input/dob_now_new_building_initial_filings_2016_2026.csv \
	../input/dob_now_new_building_amendments_2024_2026.csv ../../shared/code/write_data_report.R | ../output ../report
	$(R) $<

../input/dob_now_new_building_filing_files.csv: \
	../../fetch_dob_now_new_building_filings/output/dob_now_new_building_filing_files.csv | ../input
	ln -sf $< $@

../input/dob_now_new_building_initial_filings_2016_2026.csv: \
	../../fetch_dob_now_new_building_filings/output/dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026.csv \
	| ../input
	ln -sf $< $@

../input/dob_now_new_building_amendments_2024_2026.csv: \
	../../fetch_dob_now_new_building_filings/output/dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026.csv \
	| ../input
	ln -sf $< $@

link-inputs: ../input/dob_now_new_building_filing_files.csv ../input/dob_now_new_building_initial_filings_2016_2026.csv \
	../input/dob_now_new_building_amendments_2024_2026.csv

include ../../shared/code/generic.make
