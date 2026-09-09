include ../../shared/code/shell_functions.make

all: ../output/dcp_housing_database_project_level_raw_25q4.parquet ../output/dcp_housing_database_raw_files.csv \
	../report/dcp_housing_database_project_level_raw_25q4.txt \
	../report/dcp_housing_database_raw_files.txt

../output/dcp_housing_database_project_level_raw_25q4.parquet: load_dcp_housing_database_raw.R \
	../../shared/code/source_pipeline_utils.R ../input/dcp_housing_database_files.csv Makefile \
	../input/nychdb_25q4_csv.zip \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/dcp_housing_database_raw_files.csv: ../output/dcp_housing_database_project_level_raw_25q4.parquet
	$(MAKE) -W load_dcp_housing_database_raw.R all


../report/dcp_housing_database_project_level_raw_25q4.txt: report_data.R ../../shared/code/write_data_report.R ../output/dcp_housing_database_project_level_raw_25q4.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< dcp_housing_database_project_level_raw_25q4

../report/dcp_housing_database_raw_files.txt: report_data.R ../../shared/code/write_data_report.R ../output/dcp_housing_database_raw_files.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< dcp_housing_database_raw_files


../input/dcp_housing_database_files.csv: ../../fetch_dcp_housing_database/output/dcp_housing_database_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dcp_housing_database_files.csv

../input/nychdb_25q4_csv.zip: ../../fetch_dcp_housing_database/output/dcp_housing_database_project_level_25Q4_nychdb_25q4_csv.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../fetch_dcp_housing_database/output/dcp_housing_database_files.csv \
	../../fetch_dcp_housing_database/output/dcp_housing_database_project_level_25Q4_nychdb_25q4_csv.zip: check-fetch_dcp_housing_database ;

.PHONY: check-fetch_dcp_housing_database

check-fetch_dcp_housing_database:
	$(MAKE) -C ../../fetch_dcp_housing_database/code all ../output/dcp_housing_database_files.csv ../output/dcp_housing_database_project_level_25Q4_nychdb_25q4_csv.zip

include ../../shared/code/generic.make
