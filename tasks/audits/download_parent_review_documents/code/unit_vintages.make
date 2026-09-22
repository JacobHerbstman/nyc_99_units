include ../../../shared/code/shell_functions.make

all: ../output/nychousingdb_23q4_csv.zip

include ../../../shared/code/generic.make

../output/nychousingdb_23q4_csv.zip: ../../../fetch_dcp_housing_database/output/dcp_housing_database_project_level_23Q4_nychousingdb_23q4_csv.zip | ../output
	ln -sf $< $@
