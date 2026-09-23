include ../../../shared/code/shell_functions.make

# Records how the Attorney General offering-plan searches used by
# classify_parent_485x_exposure were acquired. Every live query runs only when
# its saved result is missing, so edits here never re-query the service.
BATCHES := 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27
SUPPLEMENT := ../../../../data_raw/nys_ag_offering_plan_matches/2026-09-22

all: ../output/nys_ag_offering_plan_search_audit.csv ../output/nys_ag_offering_plan_matches.csv \
	$(SUPPLEMENT)/historical_ag_query_supplement_2019_2022.csv \
	$(SUPPLEMENT)/historical_ag_query_supplement_2023_companions.csv

include ../../../shared/code/generic.make

# August 26, 2026 searches for the exposure universe, in 27 batches.
../output/nys_ag_offering_plan_search_audit_batch_%.csv ../output/nys_ag_offering_plan_matches_batch_%.csv: \
	| ../input/parent_485x_exposure_universe.csv ../output
	$(R) fetch_nys_ag_offering_plan_matches.R 2026-08-26 $* 27

../output/nys_ag_offering_plan_search_audit.csv ../output/nys_ag_offering_plan_matches.csv: \
	combine_nys_ag_offering_plan_match_batches.R Makefile ../input/parent_485x_exposure_universe.csv \
	$(foreach b,$(BATCHES),../output/nys_ag_offering_plan_search_audit_batch_$(b).csv ../output/nys_ag_offering_plan_matches_batch_$(b).csv) \
	../../../shared/code/source_pipeline_utils.R | ../output
	$(R) $< 27

# September 22, 2026 supplement for historical filings and 2023 companions.
# The query manifests and results are frozen captures in data_raw/.
$(SUPPLEMENT)/historical_ag_query_manifest_2019_2022.csv: | ../input/dcp_housing_database_project_level_23q4.parquet
	mkdir -p $(@D)
	$(R) prepare_historical_ag_query_supplement.R broad

$(SUPPLEMENT)/historical_ag_query_manifest_2023_companions.csv: | ../input/dcp_housing_database_project_level_23q4.parquet \
	../input/symmetric_parent_membership.parquet
	mkdir -p $(@D)
	$(R) prepare_historical_ag_query_supplement.R companions

$(SUPPLEMENT)/historical_ag_query_supplement_2019_2022.csv: | $(SUPPLEMENT)/historical_ag_query_manifest_2019_2022.csv
	$(R) fetch_historical_ag_query_supplement.R broad

$(SUPPLEMENT)/historical_ag_query_supplement_2023_companions.csv: | $(SUPPLEMENT)/historical_ag_query_manifest_2023_companions.csv
	$(R) fetch_historical_ag_query_supplement.R companions

../input/parent_485x_exposure_universe.csv: ../../../classify_parent_485x_exposure/output/parent_485x_exposure_universe.csv | ../input
	ln -sf $< $@

../input/dcp_housing_database_project_level_23q4.parquet: \
	../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_23q4.parquet | ../input
	ln -sf $< $@

../input/symmetric_parent_membership.parquet: \
	../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	ln -sf $< $@
