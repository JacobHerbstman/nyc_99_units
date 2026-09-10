include ../../shared/code/shell_functions.make

all: ../output/dob_now_new_building_filings.parquet ../output/dob_now_new_building_initial_filings.parquet \
	../report/dob_now_new_building_filings.txt ../report/dob_now_new_building_initial_filings.txt

../output/dob_now_new_building_filings.parquet: stage_dob_now_new_building_filings.R \
	../../shared/code/source_pipeline_utils.R ../input/dob_now_new_building_filing_files.csv Makefile \
	../input/dob_now_new_building_initial_filings_2016_2026.csv ../input/dob_now_new_building_amendments_2024_2026.csv \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/dob_now_new_building_initial_filings.parquet: ../output/dob_now_new_building_filings.parquet
	$(RECOVER) -W stage_dob_now_new_building_filings.R all

../report/dob_now_new_building_filings.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/dob_now_new_building_filings.parquet Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../report
	$(R) $< dob_now_new_building_filings

../report/dob_now_new_building_initial_filings.txt: report_data.R ../../shared/code/write_data_report.R \
	../output/dob_now_new_building_initial_filings.parquet Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../report
	$(R) $< dob_now_new_building_initial_filings

../input/dob_now_new_building_filing_files.csv: \
	../../fetch_dob_now_new_building_filings/output/dob_now_new_building_filing_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings_2016_2026.csv: \
	../../fetch_dob_now_new_building_filings/output/dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026.csv \
	| ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_amendments_2024_2026.csv: \
	../../fetch_dob_now_new_building_filings/output/dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026.csv \
	| ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

.PHONY: check-fetch_dob_now_new_building_filings

check-fetch_dob_now_new_building_filings:
	$(MAKE) -C ../../fetch_dob_now_new_building_filings/code all ../output/dob_now_new_building_filing_files.csv \
	../output/dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026.csv \
	../output/dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026.csv

../../fetch_dob_now_new_building_filings/output/dob_now_new_building_filing_files.csv \
	../../fetch_dob_now_new_building_filings/output/dob_now_build_job_filings_20260710_dob_now_new_building_initial_filings_2016_2026.csv \
	../../fetch_dob_now_new_building_filings/output/dob_now_build_job_filings_20260710_dob_now_new_building_amendments_2024_2026.csv: check-fetch_dob_now_new_building_filings ;

link-inputs: ../input/dob_now_new_building_filing_files.csv \
	../input/dob_now_new_building_initial_filings_2016_2026.csv ../input/dob_now_new_building_amendments_2024_2026.csv

include ../../shared/code/generic.make
