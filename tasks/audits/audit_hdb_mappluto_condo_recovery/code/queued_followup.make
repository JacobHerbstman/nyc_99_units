include ../../../shared/code/shell_functions.make

all: ../output/historical_unit_vintage_comparison.csv ../output/historical_unit_vintage_summary.csv \
	../output/livingston_hdb_vintages.csv ../output/wallabout_map_overlaps.csv ../output/wallabout_land_allocation.csv \
	../output/historical_refiling_source_review_2026-09-22.csv

include ../../../shared/code/generic.make

../output/historical_refiling_source_review_2026-09-22.csv: review_historical_refilings.R \
	queued_followup.make ../input/nychousingdb_23q4_csv.zip ../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../output/historical_unit_vintage_comparison.csv ../output/historical_unit_vintage_summary.csv \
../output/livingston_hdb_vintages.csv: compare_hdb_unit_vintages.R queued_followup.make \
	../input/nychousingdb_23q4_csv.zip ../input/dcp_housing_database_project_level_25q4.parquet \
	../input/constituent_filing_panel.parquet ../input/parent_opportunity_panel.parquet \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../output/wallabout_map_overlaps.csv ../output/wallabout_land_allocation.csv: measure_wallabout_allocation.R queued_followup.make \
	../output/dof_geometry_lots.parquet ../input/dcp_mappluto_archive_18v2_1.parquet \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../input/nychousingdb_23q4_csv.zip: ../../../fetch_dcp_housing_database/output/dcp_housing_database_project_level_23Q4_nychousingdb_23q4_csv.zip | ../input
	ln -sf $< $@
../input/dcp_housing_database_project_level_25q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet | ../input
	ln -sf $< $@
../input/constituent_filing_panel.parquet: ../../../build_estimation_panels/output/constituent_filing_panel.parquet | ../input
	ln -sf $< $@
../input/parent_opportunity_panel.parquet: ../../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	ln -sf $< $@
../input/dcp_mappluto_archive_18v2_1.parquet: ../../../stage_mappluto_lots/output/dcp_mappluto_archive_18v2_1.parquet | ../input
	ln -sf $< $@

all: ../output/prepolicy_source_changes.csv ../output/prepolicy_source_summary.csv \
	../output/prepolicy_source_status.csv ../output/prepolicy_active_comparison.csv ../output/prepolicy_source_coverage.csv

../output/prepolicy_source_changes.csv ../output/prepolicy_source_summary.csv \
../output/prepolicy_source_status.csv ../output/prepolicy_active_comparison.csv ../output/prepolicy_source_coverage.csv: \
	check_prepolicy_source_rule.R prepolicy_baseline_filings_2026-09-22.csv \
	prepolicy_baseline_parents_2026-09-22.csv queued_followup.make \
	../input/dcp_housing_database_project_level_23q4.parquet ../input/symmetric_parent_membership.parquet \
	../input/constituent_filing_panel.parquet ../input/parent_opportunity_panel.parquet \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../input/dcp_housing_database_project_level_23q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_23q4.parquet | ../input
	ln -sf $< $@
../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	ln -sf $< $@
