include ../../shared/code/shell_functions.make

all: ../output/dcp_housing_database_project_level_raw_23q4.parquet \
	../output/dcp_housing_database_project_level_23q4.parquet \
	../output/dcp_housing_database_project_level_raw_25q4.parquet \
	../output/dcp_housing_database_project_level_25q4.parquet

include ../../shared/code/generic.make

../output/dcp_housing_database_project_level_raw_23q4.parquet \
	../output/dcp_housing_database_project_level_23q4.parquet \
	../output/dcp_housing_database_project_level_raw_25q4.parquet \
	../output/dcp_housing_database_project_level_25q4.parquet: stage_dcp_housing_database.R \
	../input/nychousingdb_23q4_csv.zip ../input/nychdb_25q4_csv.zip \
	../../shared/code/source_pipeline_utils.R ../../shared/code/write_data_report.R Makefile | $(OOPR)
	$(R) $<

../input/nychdb_25q4_csv.zip: \
	../../fetch_dcp_housing_database/output/dcp_housing_database_project_level_25Q4_nychdb_25q4_csv.zip | ../input
	ln -sf $< $@

../input/nychousingdb_23q4_csv.zip: \
	../../fetch_dcp_housing_database/output/dcp_housing_database_project_level_23Q4_nychousingdb_23q4_csv.zip | ../input
	ln -sf $< $@
