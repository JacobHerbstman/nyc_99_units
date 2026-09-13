include ../../shared/code/shell_functions.make

all: ../output/dcp_housing_database_project_level_raw_25q4.parquet ../output/dcp_housing_database_raw_files.csv \
	../output/dcp_housing_database_project_level_25q4.parquet ../output/dcp_housing_database_files.csv

include ../../shared/code/generic.make

../output/dcp_housing_database_project_level_25q4.parquet ../output/dcp_housing_database_raw_files.csv \
	../output/dcp_housing_database_files.csv ../output/dcp_housing_database_project_level_raw_25q4.parquet : \
	stage_dcp_housing_database.R ../../shared/code/source_pipeline_utils.R ../input/dcp_housing_database_files.csv \
	Makefile ../input/nychdb_25q4_csv.zip ../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../input/dcp_housing_database_files.csv: ../../fetch_dcp_housing_database/output/dcp_housing_database_files.csv \
	| ../input
	ln -sf $< $@

../input/nychdb_25q4_csv.zip: \
	../../fetch_dcp_housing_database/output/dcp_housing_database_project_level_25Q4_nychdb_25q4_csv.zip | ../input
	ln -sf $< $@
