SHELL := bash
include ../../shell_functions.make

PRE_START_YEAR := 2010
PRE_END_YEAR := 2023
POST_YEAR := 2025
MIN_UNITS := 50
MAX_UNITS := 150
MAX_PARENT_UNITS := 400
BIN_WIDTH := 5

all: ../output/hdb_unit_bunching_histogram.pdf \
	../output/hdb_unit_bunching_exact.pdf \
	../output/hdb_parent_unit_multiples.pdf \
	../output/hdb_unit_bunching_counts.csv

../output/hdb_unit_bunching_histogram.pdf: summarize_hdb_unit_bunching.R \
	../../_lib/source_pipeline_utils.R \
	../input/dcp_housing_database_project_level_25q4.parquet | ../output
	$(R) $< $(PRE_START_YEAR) $(PRE_END_YEAR) $(POST_YEAR) $(MIN_UNITS) $(MAX_UNITS) $(MAX_PARENT_UNITS) $(BIN_WIDTH)

../output/hdb_unit_bunching_exact.pdf \
../output/hdb_parent_unit_multiples.pdf \
../output/hdb_unit_bunching_counts.csv: ../output/hdb_unit_bunching_histogram.pdf
	@test -s "$@"

../input/dcp_housing_database_project_level_25q4.parquet: ../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dcp_housing_database_project_level_25q4.parquet

include ../../generic.make
