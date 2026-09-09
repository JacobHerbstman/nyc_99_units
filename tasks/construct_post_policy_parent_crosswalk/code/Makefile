include ../../shared/code/shell_functions.make

START_YEAR := 2022
END_YEAR := 2026
MIN_UNITS := 6
MAX_UNITS := 1000

ifneq ($(filter command,$(origin START_YEAR) $(origin END_YEAR) $(origin MIN_UNITS) $(origin MAX_UNITS)),)
$(error These fixed-name outputs use the settings recorded in this Makefile; edit those settings here so Make tracks the change)
endif

all: ../output/post_policy_filing_link_fields.parquet \
	../report/post_policy_filing_link_fields.txt

../output/post_policy_filing_link_fields.parquet: construct_post_policy_parent_crosswalk.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/dob_now_new_building_initial_filings.parquet \
	../input/mappluto_appbbl_crosswalk.csv \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $< $(START_YEAR) $(END_YEAR) $(MIN_UNITS) $(MAX_UNITS)


../report/post_policy_filing_link_fields.txt: report_data.R ../../shared/code/write_data_report.R ../output/post_policy_filing_link_fields.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< post_policy_filing_link_fields


../input/dob_now_new_building_initial_filings.parquet: ../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_appbbl_crosswalk.csv: ../../build_mappluto_appbbl_crosswalk/output/mappluto_appbbl_crosswalk.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dob_now_new_building_initial_filings.parquet \
	../input/mappluto_appbbl_crosswalk.csv

../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet: check-stage_dob_now_new_building_filings ;

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet

../../build_mappluto_appbbl_crosswalk/output/mappluto_appbbl_crosswalk.csv: check-build_mappluto_appbbl_crosswalk ;

.PHONY: check-build_mappluto_appbbl_crosswalk

check-build_mappluto_appbbl_crosswalk:
	$(MAKE) -C ../../build_mappluto_appbbl_crosswalk/code all ../output/mappluto_appbbl_crosswalk.csv

include ../../shared/code/generic.make
