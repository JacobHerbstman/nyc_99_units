include ../../shared/code/shell_functions.make

all: ../output/dob_now_new_building_filings.parquet ../output/dob_now_new_building_initial_filings.parquet

include ../../shared/code/generic.make

../output/dob_now_new_building_initial_filings.parquet ../output/dob_now_new_building_filings.parquet: \
	stage_dob_now_new_building_filings.R ../../shared/code/source_pipeline_utils.R \
	Makefile \
	../input/dob_now_new_building_initial_filings_2016_2026.csv \
	../input/dob_now_new_building_amendments_2024_2026.csv ../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../input/dob_now_new_building_initial_filings_2016_2026.csv: \
	../../fetch_dob_now_new_building_filings/output/dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026.csv \
	| ../input
	ln -sf $< $@

../input/dob_now_new_building_amendments_2024_2026.csv: \
	../../fetch_dob_now_new_building_filings/output/dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026.csv \
	| ../input
	ln -sf $< $@
