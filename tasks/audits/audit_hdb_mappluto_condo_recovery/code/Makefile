include ../../../shared/code/shell_functions.make

all: ../output/condo_recovery_status_by_borough.csv \
	../output/condo_recovery_summary.csv \
	../output/unmatched_hdb_condo_audit.csv \
	../output/condo_crosswalk_candidates.csv \
	../output/condo_match_resolution.csv \
	../output/accepted_condo_matches.csv \
	../output/condo_recovered_sample_comparison.csv \
	../output/condo_recovery_status_by_window.csv \
	../output/condo_recovery_status_by_year.csv \
	../output/duplicate_feature_bbl_groups.csv \
	../output/large_unresolved_no_match_examples.csv

include ../../../shared/code/generic.make

all: ../output/prepolicy_old_review_queue.csv ../output/prepolicy_current_review_queue.csv

../output/prepolicy_old_review_queue.csv ../output/prepolicy_current_review_queue.csv: \
	reconcile_prepolicy_review_queue.R prepolicy_baseline_scope_2026-09-22.csv \
	prepolicy_baseline_filings_2026-09-22.csv ../input/symmetric_parent_membership.parquet \
	../output/parent_site_scope.csv ../../../shared/code/write_data_report.R Makefile | $(OOPR)
	$(R) $<

all: ../output/hdb_unit_fallback.csv

../output/hdb_unit_fallback.csv: audit_hdb_unit_fallback.R ../input/constituent_filing_panel.parquet \
	../input/symmetric_parent_membership.parquet ../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../../../shared/code/write_data_report.R Makefile | $(OOPR)
	$(R) $<

../input/constituent_filing_panel.parquet: ../../../build_estimation_panels/output/constituent_filing_panel.parquet | ../input
	ln -sf $< $@

all: ../output/parent_site_lot_envelopes.parquet ../output/parent_site_other_filings.csv \
	../output/parent_site_scope.csv ../output/parent_site_scope_summary.csv ../output/parent_site_document_coverage.csv

../output/parent_site_lot_envelopes.parquet ../output/parent_site_other_filings.csv \
../output/parent_site_scope.csv ../output/parent_site_scope_summary.csv ../output/parent_site_document_coverage.csv: audit_parent_site_scope.R parent_site_document_review.csv parent_site_membership_review.csv parent_site_filing_review.csv Makefile \
	../output/dof_parent_coverage.csv ../output/dof_events.parquet ../output/dof_condo_links.parquet \
	../output/dof_all_parent_geometry.csv ../output/dof_all_parent_overlaps.parquet ../output/dof_geometry_lots.parquet \
	../output/bis_filing_sites.csv ../output/bis_parent_site_comparison.csv \
	../input/parent_opportunity_panel.parquet ../input/symmetric_parent_membership.parquet \
	../input/dcp_housing_database_project_level_25q4.parquet ../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../input/dcp_housing_database_project_level_23q4.parquet ../input/dcp_housing_database_project_level_raw_23q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet ../input/mappluto_release_calendar.csv \
	../input/dcp_mappluto_archive_23v3_1.parquet \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../input/dcp_housing_database_project_level_25q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet | ../input
	ln -sf $< $@
../input/dcp_housing_database_project_level_raw_25q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_25q4.parquet | ../input
	ln -sf $< $@
../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@

all: ../output/bis_filing_sites.csv ../output/bis_parent_site_comparison.csv

../output/bis_filing_sites.csv ../output/bis_parent_site_comparison.csv: compare_bis_site_lots.R Makefile \
	../input/bis_site_fields.json ../input/historical_hdb_mappluto_site_panel.parquet \
	../input/symmetric_parent_membership.parquet ../input/parent_opportunity_panel.parquet \
	../output/dof_geometry_comparison.csv ../output/dof_geometry_overlaps.parquet \
	$(foreach v,18v1_1 18v2beta 18v2_1 19v2 20v1 20v2 20v3 20v4,../input/dcp_mappluto_archive_$(v).parquet) \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../input/bis_site_fields.json: ../../download_parent_review_documents/code/filing_sites_2026-09-16/bis_site_fields.json | ../input
	ln -sf $< $@

../output/condo_recovery_status_by_borough.csv \
	../output/condo_recovery_summary.csv \
	../output/unmatched_hdb_condo_audit.csv \
	../output/condo_crosswalk_candidates.csv \
	../output/condo_match_resolution.csv \
	../output/accepted_condo_matches.csv \
	../output/condo_recovered_sample_comparison.csv \
	../output/condo_recovery_status_by_window.csv \
	../output/condo_recovery_status_by_year.csv \
	../output/duplicate_feature_bbl_groups.csv \
	../output/large_unresolved_no_match_examples.csv: \
	audit_hdb_mappluto_condo_recovery.R ../../../shared/code/source_pipeline_utils.R \
	../input/hdb_mappluto_site_panel.parquet ../input/mappluto_lot_files.csv ../input/mappluto_files.csv Makefile | $(OOPR)
	$(R) audit_hdb_mappluto_condo_recovery.R

../input/hdb_mappluto_site_panel.parquet: ../../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | ../input
	ln -sf $< $@

../input/mappluto_lot_files.csv: ../../../stage_mappluto_lots/output/mappluto_lot_files.csv | ../input
	ln -sf $< $@

../input/mappluto_files.csv: ../../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	ln -sf $< $@

all: ../output/dof_lot_changes.csv ../output/dof_applications.csv

../output/dof_lot_changes.csv ../output/dof_applications.csv: review_dof_history.R \
	../../../shared/code/write_data_report.R Makefile \
	../input/dof_five_blocks_header.json ../input/dof_five_blocks_lots_0.json \
	../input/dof_tracker_five_blocks.json ../input/dof_header_page_0.json \
	../input/dof_header_page_7.json ../input/dof_five_blocks_lots_count.json | $(OOPR)
	$(R) $<

all: ../output/dof_filing_map_lots.parquet ../output/dof_filing_map_coverage.csv \
	../output/dof_filing_map_matches.csv ../output/dof_filing_map_footprints.pdf

../output/dof_filing_map_lots.parquet: read_dof_filing_maps.R Makefile \
	../output/dof_geometry_comparison.csv ../../../shared/code/write_data_report.R \
	$(foreach v,18v1_1 18v2 18v2_1 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 22v1 22v2 23v1 23v1_1 23v1_2 23v2 23v3 23v3_1,../input/nyc_mappluto_$(v)_arc_shp.zip) | $(OOPR)
	$(R) $<

../output/dof_filing_map_coverage.csv ../output/dof_filing_map_matches.csv ../output/dof_filing_map_footprints.pdf: \
	match_dof_filing_maps.R Makefile ../output/dof_filing_map_lots.parquet \
	../output/dof_events.parquet \
	../output/dof_geometry_comparison.csv ../output/dof_geometry_lots.parquet ../output/dof_parent_parcels.parquet \
	../input/parent_opportunity_panel.parquet ../input/mappluto_release_calendar.csv \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../input/mappluto_release_calendar.csv: ../../../build_hdb_mappluto_site_panel/output/mappluto_release_calendar.csv | ../input
	ln -sf $< $@

../input/dof_%.json: ../../download_parent_review_documents/code/dof_history_2026-09-15/%.json | ../input
	ln -sf $< $@

all: ../output/dof_events.parquet ../output/dof_condo_links.parquet \
	../output/dof_parent_parcels.parquet ../output/dof_parent_coverage.csv ../output/dof_coverage_summary.csv

../output/dof_events.parquet ../output/dof_condo_links.parquet: clean_dof_history.R Makefile \
	../input/dof_transaction_headers.parquet ../input/dof_lot_actions.parquet \
	../input/dof_condo_actions.parquet ../input/dof_condo_unit_actions.parquet \
	../input/dof_current_condos.parquet ../input/dof_current_condo_units.parquet \
	../input/nyc_pluto_25v4_csv.zip ../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../output/dof_parent_parcels.parquet ../output/dof_parent_coverage.csv ../output/dof_coverage_summary.csv: \
	trace_parent_parcels.R Makefile ../output/dof_events.parquet ../output/dof_condo_links.parquet \
	../input/parent_opportunity_panel.parquet ../input/symmetric_parent_membership.parquet \
	../input/hdb_mappluto_site_panel.parquet ../input/historical_hdb_mappluto_site_panel.parquet \
	../input/dof_current_lots.parquet \
	../input/dof_map_library.parquet ../input/dof_all_applications.parquet \
	../input/dcp_pluto_archive_18v1.parquet \
	$(foreach v,18v1_1 18v2beta 18v2_1 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 22v1 23v3_1,../input/dcp_mappluto_archive_$(v).parquet) \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../input/dof_transaction_headers.parquet: ../../../fetch_dof_tax_map_history/output/dtm_9.parquet | ../input
	ln -sf $< $@
../input/dof_lot_actions.parquet: ../../../fetch_dof_tax_map_history/output/dtm_15.parquet | ../input
	ln -sf $< $@
../input/dof_condo_actions.parquet: ../../../fetch_dof_tax_map_history/output/dtm_13.parquet | ../input
	ln -sf $< $@
../input/dof_condo_unit_actions.parquet: ../../../fetch_dof_tax_map_history/output/dtm_14.parquet | ../input
	ln -sf $< $@
../input/dof_current_condos.parquet: ../../../fetch_dof_tax_map_history/output/dtm_3.parquet | ../input
	ln -sf $< $@
../input/dof_current_condo_units.parquet: ../../../fetch_dof_tax_map_history/output/dtm_4.parquet | ../input
	ln -sf $< $@
../input/dof_current_lots.parquet: ../../../fetch_dof_tax_map_history/output/dtm_0.parquet | ../input
	ln -sf $< $@
../input/dof_map_library.parquet: ../../../fetch_dof_tax_map_history/output/dtm_8.parquet | ../input
	ln -sf $< $@
../input/dof_all_applications.parquet: ../../../fetch_dof_tax_map_history/output/applications.parquet | ../input
	ln -sf $< $@
../input/nyc_pluto_25v4_csv.zip: ../../../fetch_mappluto_archive/output/nyc_pluto_25v4_csv.zip | ../input
	ln -sf $< $@
../input/parent_opportunity_panel.parquet: ../../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	ln -sf $< $@
../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	ln -sf $< $@
../input/dcp_mappluto_archive_%.parquet: ../../../stage_mappluto_lots/output/dcp_mappluto_archive_%.parquet | ../input
	ln -sf $< $@
../input/dcp_pluto_archive_18v1.parquet: ../../../stage_mappluto_lots/output/dcp_pluto_archive_18v1.parquet | ../input
	ln -sf $< $@

all: ../output/dof_subset_comparison.csv ../output/dof_subset_summary.csv ../output/dof_subset_footprints.pdf

../output/dof_subset_comparison.csv ../output/dof_subset_summary.csv ../output/dof_subset_footprints.pdf: \
	measure_dof_subset.R dof_subset_review.csv dof_subset_parent_definitions_2026-09-22.csv \
	Makefile ../../../shared/code/write_data_report.R \
	../output/dof_events.parquet ../input/nyc_pluto_25v4_csv.zip \
	../input/dof_subset_filing_parcels.geojson ../input/dof_subset_godwin_companion.geojson \
	../input/nyc_mappluto_25v4_shp.zip \
	$(foreach v,18v2 20v5 20v8 21v1 23v3_1,../input/nyc_mappluto_$(v)_arc_shp.zip) | $(OOPR)
	$(R) $<

../input/dof_subset_filing_parcels.geojson: ../../download_parent_review_documents/code/dof_subset_2026-09-15/filing_parcels.geojson | ../input
	ln -sf $< $@

../input/dof_subset_godwin_companion.geojson: ../../download_parent_review_documents/output/dof_subset_godwin_companion.geojson | ../input
	ln -sf $< $@

../input/nyc_mappluto_%.zip: ../../../fetch_mappluto_archive/output/nyc_mappluto_%.zip | ../input
	ln -sf $< $@

all: ../output/dof_subset_assessment_history.csv ../output/dof_subset_lot_checks.csv \
	../output/dof_subset_waterfront_areas.csv

../output/dof_subset_assessment_history.csv ../output/dof_subset_lot_checks.csv ../output/dof_subset_waterfront_areas.csv: \
	validate_dof_subset_areas.R dof_lot_measurement_review.csv Makefile ../../../shared/code/write_data_report.R \
	../input/dof_subset_assessments.json ../input/dof_subset_assessment_count.json \
	../output/dof_subset_comparison.csv ../input/nyc_pluto_25v4_csv.zip \
	../input/dof_subset_filing_parcels.geojson ../input/nyc_mappluto_25v4_shp.zip | $(OOPR)
	$(R) $<

../input/dof_subset_assessments.json: ../../download_parent_review_documents/code/dof_subset_validation_2026-09-15/assessments.json | ../input
	ln -sf $< $@

../input/dof_subset_assessment_count.json: ../../download_parent_review_documents/code/dof_subset_validation_2026-09-15/assessment_count.json | ../input
	ln -sf $< $@

all: ../output/dof_geometry_lots.parquet

../output/dof_geometry_lots.parquet: read_dof_geometry.R Makefile \
	../output/dof_parent_coverage.csv ../output/dof_parent_parcels.parquet ../output/dof_condo_links.parquet \
	../input/nyc_mappluto_25v4_shp.zip \
	$(foreach v,18v1_1 18v2 18v2_1 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 22v1 23v3_1,../input/nyc_mappluto_$(v)_arc_shp.zip) \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

all: ../output/dof_geometry_overlaps.parquet ../output/dof_geometry_comparison.csv ../output/dof_geometry_summary.csv \
	../output/dof_all_parent_geometry.csv ../output/dof_all_parent_overlaps.parquet

../output/dof_geometry_overlaps.parquet ../output/dof_geometry_comparison.csv ../output/dof_geometry_summary.csv \
../output/dof_all_parent_geometry.csv ../output/dof_all_parent_overlaps.parquet: \
	compare_dof_geometry.R Makefile ../output/dof_geometry_lots.parquet \
	../output/dof_parent_coverage.csv ../output/dof_parent_parcels.parquet ../output/dof_condo_links.parquet \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

all: ../output/dof_geometry_overview.pdf ../output/dof_geometry_overview.png ../output/dof_geometry_footprints.pdf

../output/dof_geometry_overview.pdf ../output/dof_geometry_overview.png ../output/dof_geometry_footprints.pdf: \
	plot_dof_geometry.R Makefile ../output/dof_geometry_comparison.csv ../output/dof_geometry_summary.csv \
	../output/dof_geometry_overlaps.parquet ../output/dof_geometry_lots.parquet ../output/dof_parent_parcels.parquet | $(OOPR)
	$(R) $<

../input/historical_hdb_mappluto_site_panel.parquet: ../../../build_hdb_mappluto_site_panel/output/historical_hdb_mappluto_site_panel.parquet | ../input
	ln -sf $< $@

../input/dcp_housing_database_project_level_23q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_23q4.parquet | ../input
	ln -sf $< $@
../input/dcp_housing_database_project_level_raw_23q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_23q4.parquet | ../input
	ln -sf $< $@
