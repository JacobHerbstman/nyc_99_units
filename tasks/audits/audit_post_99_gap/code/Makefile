include ../../../shared/code/shell_functions.make

POST_START_DATE := 2025-01-01

ifeq ($(origin POST_START_DATE),command line)
$(error Edit POST_START_DATE in this tracked Makefile so fixed-name results rebuild)
endif

all: ../output/post_99_next_observed_unit_audit.csv ../output/post_105_parent_cases.csv \
	../report/post_99_next_observed_unit_audit.txt \
	../report/post_105_parent_cases.txt

../output/post_99_next_observed_unit_audit.csv: audit_post_99_gap.R ../../../shared/code/source_pipeline_utils.R Makefile ../input/symmetric_parent_membership.parquet ../input/dob_now_new_building_initial_filings.parquet ../input/dob_now_new_building_filings.parquet ../input/parent_485x_exposure.csv \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< $(POST_START_DATE)

../output/post_105_parent_cases.csv: ../output/post_99_next_observed_unit_audit.csv
	$(RECOVER) -W audit_post_99_gap.R all

../report/post_99_next_observed_unit_audit.txt: report_data.R ../../../shared/code/write_data_report.R ../output/post_99_next_observed_unit_audit.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< post_99_next_observed_unit_audit

../report/post_105_parent_cases.txt: report_data.R ../../../shared/code/write_data_report.R ../output/post_105_parent_cases.csv Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../report
	$(R) $< post_105_parent_cases

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/parent_485x_exposure.csv: ../../../classify_parent_485x_exposure/output/parent_485x_exposure.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet: check-construct_parent_cohorts ;

.PHONY: check-construct_parent_cohorts

check-construct_parent_cohorts:
	$(MAKE) -C ../../../construct_parent_cohorts/code all ../output/symmetric_parent_membership.parquet

../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet \
	../../../stage_dob_now_new_building_filings/output/dob_now_new_building_filings.parquet: check-stage_dob_now_new_building_filings ;

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet ../output/dob_now_new_building_filings.parquet

../../../classify_parent_485x_exposure/output/parent_485x_exposure.csv: check-classify_parent_485x_exposure ;

.PHONY: check-classify_parent_485x_exposure

check-classify_parent_485x_exposure:
	$(MAKE) -C ../../../classify_parent_485x_exposure/code all ../output/parent_485x_exposure.csv

include ../../../shared/code/generic.make
