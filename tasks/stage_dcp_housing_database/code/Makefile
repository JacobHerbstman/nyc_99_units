include ../../shared/code/shell_functions.make

all: ../output/dcp_housing_database_project_level_25q4.parquet ../output/dcp_housing_database_files.csv \
	../report/dcp_housing_database_files.txt \
	../report/dcp_housing_database_project_level_25q4.txt

../output/dcp_housing_database_project_level_25q4.parquet: stage_dcp_housing_database.R \
	../../shared/code/source_pipeline_utils.R ../input/dcp_housing_database_raw_files.csv Makefile \
	../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<


../output/dcp_housing_database_files.csv: ../output/dcp_housing_database_project_level_25q4.parquet
	$(MAKE) -W stage_dcp_housing_database.R all


../report/dcp_housing_database_files.txt: report_data.R ../../shared/code/write_data_report.R ../output/dcp_housing_database_files.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< dcp_housing_database_files

../report/dcp_housing_database_project_level_25q4.txt: report_data.R ../../shared/code/write_data_report.R ../output/dcp_housing_database_project_level_25q4.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< dcp_housing_database_project_level_25q4


../input/dcp_housing_database_raw_files.csv: ../../load_dcp_housing_database_raw/output/dcp_housing_database_raw_files.csv | ../input
	@test "$$(readlink "$@")" = "../../load_dcp_housing_database_raw/output/dcp_housing_database_raw_files.csv" || ln -sf "../../load_dcp_housing_database_raw/output/dcp_housing_database_raw_files.csv" "$@"

link-inputs: ../input/dcp_housing_database_raw_files.csv

../input/dcp_housing_database_project_level_raw_25q4.parquet: ../../load_dcp_housing_database_raw/output/dcp_housing_database_project_level_raw_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../load_dcp_housing_database_raw/output/dcp_housing_database_raw_files.csv \
	../../load_dcp_housing_database_raw/output/dcp_housing_database_project_level_raw_25q4.parquet: check-load_dcp_housing_database_raw ;

.PHONY: check-load_dcp_housing_database_raw

check-load_dcp_housing_database_raw:
	$(MAKE) -C ../../load_dcp_housing_database_raw/code all ../output/dcp_housing_database_raw_files.csv ../output/dcp_housing_database_project_level_raw_25q4.parquet

include ../../shared/code/generic.make
