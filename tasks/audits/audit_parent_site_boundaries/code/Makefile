include ../../../shared/code/shell_functions.make

# Reference releases used by the parcel trace, the map comparison and the
# filing-site comparison.
TRACE_RELEASES := 18v1_1 18v2beta 18v2_1 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 22v1 23v3_1
GEOMETRY_RELEASES := 18v1_1 18v2 18v2_1 19v1 19v2 20v1 20v2 20v3 20v4 20v5 20v6 20v7 20v8 21v1 21v3 22v1 23v3_1
BIS_RELEASES := 18v1_1 18v2beta 18v2_1 19v2 20v1 20v2 20v3 20v4

all: ../output/parent_site_scope.csv ../output/parent_site_scope_summary.csv \
	../output/parent_site_lot_envelopes.parquet ../output/parent_site_other_filings.csv \
	../output/parent_site_document_coverage.csv \
	../output/jamaica_floor_allocation.csv ../output/kingsbrook_floor_schedule.csv \
	../output/remaining_floor_candidates.csv ../output/kingsbrook_floor_allocation.png \
	../output/wallabout_map_overlaps.csv ../output/wallabout_land_allocation.csv

include ../../../shared/code/generic.make

# DOF transactions and condominium links.
../output/dof_events.parquet ../output/dof_condo_links.parquet: clean_dof_history.R Makefile \
	../input/dof_transaction_headers.parquet ../input/dof_lot_actions.parquet \
	../input/dof_condo_actions.parquet ../input/dof_condo_unit_actions.parquet \
	../input/dof_current_condos.parquet ../input/dof_current_condo_units.parquet \
	../input/nyc_pluto_25v4_csv.zip ../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

# Each parent's filing lots traced back to its reference release.
../output/dof_parent_parcels.parquet ../output/dof_parent_coverage.csv ../output/dof_coverage_summary.csv: \
	trace_parent_parcels.R Makefile ../output/dof_events.parquet ../output/dof_condo_links.parquet \
	../input/parent_opportunity_panel.parquet ../input/symmetric_parent_membership.parquet \
	../input/hdb_mappluto_site_panel.parquet ../input/historical_hdb_mappluto_site_panel.parquet \
	../input/dof_current_lots.parquet ../input/dof_map_library.parquet ../input/dof_all_applications.parquet \
	../input/dcp_pluto_archive_18v1.parquet \
	$(foreach v,$(TRACE_RELEASES),../input/dcp_mappluto_archive_$(v).parquet) \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

# Earlier and later parcel outlines for the traced lots.
../output/dof_geometry_lots.parquet: read_dof_geometry.R Makefile \
	../output/dof_parent_coverage.csv ../output/dof_parent_parcels.parquet ../output/dof_condo_links.parquet \
	../input/nyc_mappluto_25v4_shp.zip \
	$(foreach v,$(GEOMETRY_RELEASES),../input/nyc_mappluto_$(v)_arc_shp.zip) \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../output/dof_geometry_overlaps.parquet ../output/dof_geometry_comparison.csv ../output/dof_geometry_summary.csv \
	../output/dof_all_parent_geometry.csv ../output/dof_all_parent_overlaps.parquet: \
	compare_dof_geometry.R Makefile ../output/dof_geometry_lots.parquet \
	../output/dof_parent_coverage.csv ../output/dof_parent_parcels.parquet ../output/dof_condo_links.parquet \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

# Saved DOB site fields compared with the mapped filing lots.
../output/bis_filing_sites.csv ../output/bis_parent_site_comparison.csv: compare_bis_site_lots.R Makefile \
	../input/bis_site_fields.json ../input/historical_hdb_mappluto_site_panel.parquet \
	../input/symmetric_parent_membership.parquet ../input/parent_opportunity_panel.parquet \
	../output/dof_geometry_comparison.csv ../output/dof_geometry_overlaps.parquet \
	$(foreach v,$(BIS_RELEASES),../input/dcp_mappluto_archive_$(v).parquet) \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

# The boundary screen: one row per weighting-sample parent.
../output/parent_site_scope.csv ../output/parent_site_scope_summary.csv \
	../output/parent_site_lot_envelopes.parquet ../output/parent_site_other_filings.csv \
	../output/parent_site_document_coverage.csv: audit_parent_site_scope.R Makefile \
	parent_site_document_review.csv parent_site_membership_review.csv parent_site_filing_review.csv \
	../output/dof_parent_coverage.csv ../output/dof_events.parquet ../output/dof_condo_links.parquet \
	../output/dof_all_parent_geometry.csv ../output/dof_all_parent_overlaps.parquet ../output/dof_geometry_lots.parquet \
	../output/bis_filing_sites.csv ../output/bis_parent_site_comparison.csv \
	../input/parent_opportunity_panel.parquet ../input/symmetric_parent_membership.parquet \
	../input/dcp_housing_database_project_level_25q4.parquet ../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../input/dcp_housing_database_project_level_23q4.parquet ../input/dcp_housing_database_project_level_raw_23q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet ../input/mappluto_release_calendar.csv \
	../input/dcp_mappluto_archive_23v3_1.parquet ../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

# Calculations behind adopted allocations in parent_opportunities_manual.
../output/jamaica_floor_allocation.csv ../output/kingsbrook_floor_schedule.csv \
	../output/remaining_floor_candidates.csv ../output/kingsbrook_floor_allocation.png: \
	measure_remaining_floors.R kingsbrook_survey_tracing.csv Makefile \
	../input/dcp_mappluto_archive_23v3_1.parquet ../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../output/wallabout_map_overlaps.csv ../output/wallabout_land_allocation.csv: measure_wallabout_allocation.R \
	Makefile ../output/dof_geometry_lots.parquet ../input/dcp_mappluto_archive_18v2_1.parquet \
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
../input/nyc_mappluto_%.zip: ../../../fetch_mappluto_archive/output/nyc_mappluto_%.zip | ../input
	ln -sf $< $@
../input/dcp_mappluto_archive_%.parquet: ../../../stage_mappluto_lots/output/dcp_mappluto_archive_%.parquet | ../input
	ln -sf $< $@
../input/dcp_pluto_archive_18v1.parquet: ../../../stage_mappluto_lots/output/dcp_pluto_archive_18v1.parquet | ../input
	ln -sf $< $@
../input/hdb_mappluto_site_panel.parquet: ../../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | ../input
	ln -sf $< $@
../input/historical_hdb_mappluto_site_panel.parquet: ../../../build_hdb_mappluto_site_panel/output/historical_hdb_mappluto_site_panel.parquet | ../input
	ln -sf $< $@
../input/mappluto_release_calendar.csv: ../../../build_hdb_mappluto_site_panel/output/mappluto_release_calendar.csv | ../input
	ln -sf $< $@
../input/dcp_housing_database_project_level_%.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_%.parquet | ../input
	ln -sf $< $@
../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@
../input/parent_opportunity_panel.parquet: ../../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	ln -sf $< $@
../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	ln -sf $< $@
../input/bis_site_fields.json: ../../parent_review_documents/output/filing_sites_2026-09-16/bis_site_fields.json | ../input
	ln -sf $< $@
