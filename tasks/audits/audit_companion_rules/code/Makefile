include ../../../shared/code/shell_functions.make

all: ../output/filing_identity.parquet ../output/candidate_pairs.parquet ../output/rule_summary.csv \
	../output/rule_parent_outcomes.csv ../output/strict_rule_sensitivity.csv ../output/strict_rule_splits.csv

include ../../../shared/code/generic.make

../output/filing_identity.parquet: build_filing_identity.R ../input/symmetric_parent_membership.parquet \
	../input/dob_now_new_building_initial_filings.parquet ../input/dob_bis_nb_initial_filings.csv \
	../input/dcp_housing_database_project_level_raw_23q4.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../../../shared/code/write_data_report.R Makefile | $(OOPR)
	$(R) $<

../output/candidate_pairs.parquet ../output/rule_summary.csv: evaluate_companion_rules.R rule_definitions.R \
	../output/filing_identity.parquet ../input/dof_transaction_headers.parquet ../input/dof_lot_actions.parquet \
	../../../shared/code/write_data_report.R Makefile | $(OOPR)
	$(R) $<

../output/rule_parent_outcomes.csv: simulate_rule_parents.R rule_definitions.R ../output/candidate_pairs.parquet \
	../input/parent_opportunity_panel.parquet ../input/constituent_filing_panel.parquet \
	../input/pair_decisions.csv ../input/symmetric_parent_membership.parquet \
	../../../shared/code/write_data_report.R Makefile | $(OOPR)
	$(R) $<

../output/strict_rule_sensitivity.csv ../output/strict_rule_splits.csv: strict_rule_sensitivity.R \
	../input/symmetric_parent_links.parquet ../input/owner_proximity_links.parquet \
	../input/symmetric_parent_membership.parquet ../input/parent_opportunity_panel.parquet \
	../input/constituent_filing_panel.parquet ../../../shared/code/scale_shape_helpers.R \
	../../../shared/code/write_data_report.R Makefile | $(OOPR)
	$(R) $<

../input/parent_opportunity_panel.parquet: ../../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	ln -sf $< $@
../input/constituent_filing_panel.parquet: ../../../build_estimation_panels/output/constituent_filing_panel.parquet | ../input
	ln -sf $< $@
../input/pair_decisions.csv: ../../../parent_opportunities_manual/output/pair_decisions.csv | ../input
	ln -sf $< $@
../input/dof_transaction_headers.parquet: ../../../fetch_dof_tax_map_history/output/dtm_9.parquet | ../input
	ln -sf $< $@
../input/dof_lot_actions.parquet: ../../../fetch_dof_tax_map_history/output/dtm_15.parquet | ../input
	ln -sf $< $@
../input/symmetric_parent_links.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_links.parquet | ../input
	ln -sf $< $@
../input/owner_proximity_links.parquet: ../../../construct_parent_cohorts/output/owner_proximity_links.parquet | ../input
	ln -sf $< $@
../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	ln -sf $< $@
../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@
../input/dob_bis_nb_initial_filings.csv: ../../../fetch_dob_bis_job_filings/output/dob_bis_job_filings_20260923_nb_initial_filings.csv | ../input
	ln -sf $< $@
../input/dcp_housing_database_project_level_raw_%.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_%.parquet | ../input
	ln -sf $< $@
