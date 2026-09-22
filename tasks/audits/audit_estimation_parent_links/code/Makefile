include ../../../shared/code/shell_functions.make

all: ../output/dob_unit_filings.csv ../output/dob_unit_parents.csv \
	../output/refilings.csv ../output/companion_link_trace.csv \
	../output/third_avenue_plan.png ../output/nearby_filings.csv \
	../output/parent_constituents.csv ../output/parent_review_coverage.csv ../output/parent_casebook.md

include ../../../shared/code/generic.make

../output/dob_unit_filings.csv ../output/dob_unit_parents.csv: compare_unit_sources.R Makefile \
	../../../shared/code/write_data_report.R ../input/parent_opportunity_panel.parquet \
	../input/symmetric_parent_membership.parquet ../input/dob_now_new_building_initial_filings.parquet \
	../input/dcp_housing_database_project_level_raw_23q4.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet | $(OOPR)
	$(R) $<

../output/refilings.csv: review_refilings.R Makefile ../../../shared/code/write_data_report.R \
	../input/symmetric_parent_membership.parquet ../input/dob_now_new_building_initial_filings.parquet \
	../input/dcp_housing_database_project_level_23q4.parquet | $(OOPR)
	$(R) $<

../output/companion_link_trace.csv: trace_companions.R Makefile ../../../shared/code/write_data_report.R \
	../input/symmetric_parent_membership.parquet ../input/post_policy_filing_link_fields.parquet \
	../input/historical_parent_filing_link_fields.parquet ../input/historical_parent_candidate_pairs.parquet \
	../input/historical_hdb_mappluto_site_panel.parquet ../input/symmetric_parent_links.parquet \
	../input/nyc_mappluto_23v3_1_arc_shp.zip | $(OOPR)
	$(R) $<

../output/third_avenue_plan.png: ../input/4121_third_rawp_2025-10-01.pdf Makefile | $(OOPR)
	pdftoppm -f 77 -l 77 -singlefile -scale-to 2600 -png $< ../output/third_avenue_plan

../output/parent_constituents.csv ../output/parent_casebook.md ../output/parent_review_coverage.csv: review_parents.R Makefile \
	../../../shared/code/write_data_report.R parent_evidence.csv ../output/refilings.csv ../output/nearby_filings.csv \
	../input/parent_opportunity_panel.parquet ../input/symmetric_parent_membership.parquet \
	../input/symmetric_parent_links.parquet ../input/historical_parent_filing_link_fields.parquet \
	../input/dcp_housing_database_project_level_raw_23q4.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet ../input/dob_now_new_building_filings.parquet \
	../input/prepolicy_baseline_filings_2026-09-22.csv | $(OOPR)
	$(R) $<

../output/nearby_filings.csv: screen_neighbors.R Makefile ../../../shared/code/write_data_report.R \
	neighbor_evidence.csv ../input/pair_decisions.csv ../input/parent_opportunity_panel.parquet \
	../input/symmetric_parent_membership.parquet ../input/dcp_housing_database_project_level_raw_23q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet ../input/historical_parent_filing_link_fields.parquet | $(OOPR)
	$(R) $< 200 365

../input/parent_opportunity_panel.parquet: ../../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	ln -sf $< $@

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	ln -sf $< $@

../input/symmetric_parent_links.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_links.parquet | ../input
	ln -sf $< $@

../input/historical_parent_filing_link_fields.parquet: ../../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet | ../input
	ln -sf $< $@

../input/dcp_housing_database_project_level_raw_25q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_25q4.parquet | ../input
	ln -sf $< $@

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@

../input/dob_now_new_building_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_filings.parquet | ../input
	ln -sf $< $@

../input/post_policy_filing_link_fields.parquet: ../../../construct_parent_cohorts/output/post_policy_filing_link_fields.parquet | ../input
	ln -sf $< $@

../input/historical_parent_candidate_pairs.parquet: ../../../construct_historical_parent_links/output/historical_parent_candidate_pairs.parquet | ../input
	ln -sf $< $@

../input/nyc_mappluto_23v3_1_arc_shp.zip: ../../../fetch_mappluto_archive/output/nyc_mappluto_23v3_1_arc_shp.zip | ../input
	ln -sf $< $@

../input/4121_third_rawp_2025-10-01.pdf: ../../download_parent_review_documents/output/4121_third_rawp_2025-10-01.pdf | ../input
	ln -sf $< $@

../input/pair_decisions.csv: ../../../parent_opportunities_manual/output/pair_decisions.csv | ../input
	ln -sf $< $@

../input/historical_hdb_mappluto_site_panel.parquet: ../../../build_hdb_mappluto_site_panel/output/historical_hdb_mappluto_site_panel.parquet | ../input
	ln -sf $< $@

../input/dcp_housing_database_project_level_raw_23q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_23q4.parquet | ../input
	ln -sf $< $@

../input/dcp_housing_database_project_level_23q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_23q4.parquet | ../input
	ln -sf $< $@

../input/prepolicy_baseline_filings_2026-09-22.csv: ../../audit_hdb_mappluto_condo_recovery/code/prepolicy_baseline_filings_2026-09-22.csv | ../input
	ln -sf $< $@
