SHELL := bash
include ../../shell_functions.make

START_YEAR := 2022
END_YEAR := 2026
MIN_UNITS := 6
MAX_UNITS := 1000

all: ../output/post_policy_filing_link_fields.parquet

../output/post_policy_filing_link_fields.parquet: construct_post_policy_parent_crosswalk.R \
	../../_lib/source_pipeline_utils.R \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/mappluto_appbbl_crosswalk.csv | ../output
	$(R) $< $(START_YEAR) $(END_YEAR) $(MIN_UNITS) $(MAX_UNITS)

../input/dob_now_new_building_initial_filings.parquet: ../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_appbbl_crosswalk.csv: ../../build_mappluto_appbbl_crosswalk/output/mappluto_appbbl_crosswalk.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dob_now_new_building_initial_filings.parquet \
	../input/mappluto_appbbl_crosswalk.csv

include ../../generic.make
