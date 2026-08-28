SHELL := bash
include ../../../shell_functions.make

SOURCE_PULL_DATE := 2026-08-26
BATCH_COUNT := 27
BATCHES := 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27

all: ../output/nys_ag_offering_plan_search_audit.csv \
	../output/nys_ag_offering_plan_matches.csv

../output/nys_ag_offering_plan_search_audit.csv: combine_nys_ag_offering_plan_match_batches.R \
	$(addprefix ../output/nys_ag_offering_plan_search_audit_batch_,$(addsuffix .csv,$(BATCHES))) \
	$(addprefix ../output/nys_ag_offering_plan_matches_batch_,$(addsuffix .csv,$(BATCHES))) \
	../../../_lib/source_pipeline_utils.R \
	../input/parent_485x_exposure_universe.csv | ../output
	$(R) $< $(BATCH_COUNT)

../output/nys_ag_offering_plan_matches.csv: ../output/nys_ag_offering_plan_search_audit.csv
	@test -s "$@"

../output/nys_ag_offering_plan_search_audit_batch_%.csv: fetch_nys_ag_offering_plan_matches.R \
	Makefile \
	../../../_lib/source_pipeline_utils.R \
	../input/parent_485x_exposure_universe.csv | ../output
	$(R) $< $(SOURCE_PULL_DATE) $* $(BATCH_COUNT)

../output/nys_ag_offering_plan_matches_batch_%.csv: ../output/nys_ag_offering_plan_search_audit_batch_%.csv
	@test -s "$@"

../input/parent_485x_exposure_universe.csv: ../../../build_parent_485x_exposure_universe/output/parent_485x_exposure_universe.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/parent_485x_exposure_universe.csv

include ../../generic.make
