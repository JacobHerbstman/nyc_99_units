include ../../shared/code/shell_functions.make

all: ../output/dcp_housing_database_project_level_raw_25q4.parquet ../output/dcp_housing_database_raw_files.csv \
	../output/dcp_housing_database_project_level_25q4.parquet ../output/dcp_housing_database_files.csv \
	../report/dcp_housing_database_files.txt ../report/dcp_housing_database_project_level_25q4.txt \
	../report/dcp_housing_database_project_level_raw_25q4.txt ../report/dcp_housing_database_raw_files.txt

../output/dcp_housing_database_project_level_25q4.parquet ../output/dcp_housing_database_raw_files.csv \
	../output/dcp_housing_database_files.csv ../output/dcp_housing_database_project_level_raw_25q4.parquet \
	../report/dcp_housing_database_files.txt ../report/dcp_housing_database_project_level_25q4.txt \
	../report/dcp_housing_database_project_level_raw_25q4.txt ../report/dcp_housing_database_raw_files.txt: \
	stage_dcp_housing_database.R ../../shared/code/source_pipeline_utils.R ../input/dcp_housing_database_files.csv \
	Makefile ../input/nychdb_25q4_csv.zip ../../shared/code/write_data_report.R | ../output ../report
	$(R) $<

../input/dcp_housing_database_files.csv: ../../fetch_dcp_housing_database/output/dcp_housing_database_files.csv | \
	../input
	ln -sf $< $@

../input/nychdb_25q4_csv.zip: \
	../../fetch_dcp_housing_database/output/dcp_housing_database_project_level_25Q4_nychdb_25q4_csv.zip | ../input
	ln -sf $< $@

link-inputs: ../input/dcp_housing_database_files.csv ../input/nychdb_25q4_csv.zip

include ../../shared/code/generic.make
