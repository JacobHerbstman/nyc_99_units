include ../../../shared/code/shell_functions.make

all: ../output/dob_now_new_building_initial_filings_qc.csv \
	../output/dob_now_bbl_field_summary.csv \
	../output/dob_now_bbl_field_disagreements.csv

../output/dob_now_new_building_initial_filings_qc.csv: audit_dob_now_new_building_filings.R \
	../../../shared/code/source_pipeline_utils.R ../input/dob_now_new_building_filings.parquet \
	../input/dob_now_new_building_initial_filings.parquet Makefile \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/dob_now_bbl_field_summary.csv: ../output/dob_now_new_building_initial_filings_qc.csv

../output/dob_now_bbl_field_disagreements.csv: ../output/dob_now_new_building_initial_filings_qc.csv

../input/dob_now_new_building_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dob_now_new_building_filings.parquet \
	../input/dob_now_new_building_initial_filings.parquet

../../../stage_dob_now_new_building_filings/output/dob_now_new_building_filings.parquet \
	../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet: check-stage_dob_now_new_building_filings ;

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_filings.parquet ../output/dob_now_new_building_initial_filings.parquet

include ../../../shared/code/generic.make
