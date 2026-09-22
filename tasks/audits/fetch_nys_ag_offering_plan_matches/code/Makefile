include ../../../shared/code/shell_functions.make

SOURCE_PULL_DATE := 2026-08-26
BATCH_COUNT := 27
BATCHES := 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27
HISTORICAL_SUPPLEMENT_DIR := ../../../../data_raw/nys_ag_offering_plan_matches/2026-09-22

all: ../output/nys_ag_offering_plan_search_audit.csv \
	../output/nys_ag_offering_plan_matches.csv

historical-broad-supplement: $(HISTORICAL_SUPPLEMENT_DIR)/historical_ag_query_supplement_2019_2022.csv

historical-companion-supplement: $(HISTORICAL_SUPPLEMENT_DIR)/historical_ag_query_supplement_2023_companions.csv

historical-supplement: historical-broad-supplement historical-companion-supplement

$(HISTORICAL_SUPPLEMENT_DIR)/historical_ag_query_supplement_2019_2022.csv: \
	fetch_historical_ag_query_supplement.R \
	$(HISTORICAL_SUPPLEMENT_DIR)/historical_ag_query_manifest_2019_2022.csv \
	../../../shared/code/source_pipeline_utils.R Makefile | $(HISTORICAL_SUPPLEMENT_DIR)
	$(R) $< broad

$(HISTORICAL_SUPPLEMENT_DIR)/historical_ag_query_supplement_2023_companions.csv: \
	fetch_historical_ag_query_supplement.R \
	$(HISTORICAL_SUPPLEMENT_DIR)/historical_ag_query_manifest_2023_companions.csv \
	../../../shared/code/source_pipeline_utils.R Makefile | $(HISTORICAL_SUPPLEMENT_DIR)
	$(R) $< companions

$(HISTORICAL_SUPPLEMENT_DIR)/historical_ag_query_manifest_2019_2022.csv: \
	prepare_historical_ag_query_supplement.R \
	../input/dcp_housing_database_project_level_23q4.parquet \
	../../../../data_raw/nys_ag_offering_plan_matches/2026-08-26/nys_ag_offering_plan_search_audit.csv \
	../../../shared/code/source_pipeline_utils.R Makefile | $(HISTORICAL_SUPPLEMENT_DIR)
	$(R) $< broad

$(HISTORICAL_SUPPLEMENT_DIR)/historical_ag_query_manifest_2023_companions.csv: \
	prepare_historical_ag_query_supplement.R \
	../input/dcp_housing_database_project_level_23q4.parquet \
	../input/symmetric_parent_membership.parquet \
	../../../../data_raw/nys_ag_offering_plan_matches/2026-08-26/nys_ag_offering_plan_search_audit.csv \
	../../../shared/code/source_pipeline_utils.R Makefile | $(HISTORICAL_SUPPLEMENT_DIR)
	$(R) $< companions

$(HISTORICAL_SUPPLEMENT_DIR):
	mkdir -p $@

../input/dcp_housing_database_project_level_23q4.parquet: \
		../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_23q4.parquet | ../input
	ln -sf $< $@

../input/symmetric_parent_membership.parquet: \
		../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	ln -sf $< $@

.PHONY: historical-broad-supplement historical-companion-supplement historical-supplement

../output/nys_ag_offering_plan_search_audit.csv: combine_nys_ag_offering_plan_match_batches.R Makefile \
	$(addprefix ../output/nys_ag_offering_plan_search_audit_batch_,$(addsuffix .csv,$(BATCHES))) $(addprefix \
	../output/nys_ag_offering_plan_matches_batch_,$(addsuffix .csv,$(BATCHES))) \
	../../../shared/code/source_pipeline_utils.R ../input/parent_485x_exposure_universe.csv \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< $(BATCH_COUNT)

../output/nys_ag_offering_plan_matches.csv: ../output/nys_ag_offering_plan_search_audit.csv
	$(RECOVER) -W combine_nys_ag_offering_plan_match_batches.R ../output/nys_ag_offering_plan_search_audit.csv

../output/nys_ag_offering_plan_search_audit_batch_%.csv: fetch_nys_ag_offering_plan_matches.R Makefile \
	../../../shared/code/source_pipeline_utils.R ../input/parent_485x_exposure_universe.csv \
	../../../shared/code/shell_functions.make ../../../shared/code/shell_functions.sh | ../output
	$(R) $< $(SOURCE_PULL_DATE) $* $(BATCH_COUNT)

../output/nys_ag_offering_plan_matches_batch_%.csv: ../output/nys_ag_offering_plan_search_audit_batch_%.csv
	$(RECOVER) -W fetch_nys_ag_offering_plan_matches.R ../output/nys_ag_offering_plan_search_audit_batch_$*.csv

../input/parent_485x_exposure_universe.csv: ../../../classify_parent_485x_exposure/output/parent_485x_exposure_universe.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/parent_485x_exposure_universe.csv

../../../classify_parent_485x_exposure/output/parent_485x_exposure_universe.csv: check-classify_parent_485x_exposure ;

.PHONY: check-classify_parent_485x_exposure

check-classify_parent_485x_exposure:
	$(MAKE) -C ../../../classify_parent_485x_exposure/code all ../output/parent_485x_exposure_universe.csv

include ../../../shared/code/generic.make
