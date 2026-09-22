include ../../shared/code/shell_functions.make

all: ../output/dcp_housing_database_project_level_raw_25q4.parquet ../output/dcp_housing_database_raw_files.csv \
	../output/dcp_housing_database_project_level_25q4.parquet ../output/dcp_housing_database_files.csv \
	../output/dcp_housing_database_project_level_raw_23q4.parquet ../output/dcp_housing_database_raw_files_23q4.csv \
	../output/dcp_housing_database_project_level_23q4.parquet ../output/dcp_housing_database_files_23q4.csv

include ../../shared/code/generic.make

../output/dcp_housing_database_project_level_25q4.parquet ../output/dcp_housing_database_raw_files.csv \
	../output/dcp_housing_database_files.csv ../output/dcp_housing_database_project_level_raw_25q4.parquet : \
	stage_dcp_housing_database.R ../../shared/code/source_pipeline_utils.R ../input/dcp_housing_database_files.csv \
	Makefile ../input/nychdb_25q4_csv.zip ../../shared/code/write_data_report.R | $(OOPR)
	$(R) $< 25Q4

../output/dcp_housing_database_project_level_23q4.parquet ../output/dcp_housing_database_raw_files_23q4.csv \
	../output/dcp_housing_database_files_23q4.csv ../output/dcp_housing_database_project_level_raw_23q4.parquet: \
	stage_dcp_housing_database.R ../../shared/code/source_pipeline_utils.R ../input/dcp_housing_database_files.csv \
	Makefile ../input/nychousingdb_23q4_csv.zip ../../shared/code/write_data_report.R | $(OOPR)
	$(R) $< 23Q4

../input/dcp_housing_database_files.csv: ../../fetch_dcp_housing_database/output/dcp_housing_database_files.csv \
	| ../input
	ln -sf $< $@

../input/nychdb_25q4_csv.zip: \
	../../fetch_dcp_housing_database/output/dcp_housing_database_project_level_25Q4_nychdb_25q4_csv.zip | ../input
	ln -sf $< $@

../input/nychousingdb_23q4_csv.zip: \
	../../fetch_dcp_housing_database/output/dcp_housing_database_project_level_23Q4_nychousingdb_23q4_csv.zip | ../input
	ln -sf $< $@
