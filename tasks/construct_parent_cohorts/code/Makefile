include ../../shared/code/shell_functions.make

all: ../output/post_policy_filing_link_fields.parquet ../output/symmetric_parent_links.parquet \
	../output/symmetric_parent_membership.parquet

include ../../shared/code/generic.make

../output/symmetric_parent_links.parquet ../output/symmetric_parent_membership.parquet: \
	construct_parent_cohorts.R Makefile ../input/dob_now_new_building_initial_filings.parquet \
	../input/nyc_mappluto_23v3_1_arc_shp.zip ../input/pair_decisions.csv ../input/post_parent_reviews.csv \
	../input/unit_decisions.csv ../input/post_parent_filing_roles.csv ../../shared/code/source_pipeline_utils.R \
	../input/historical_parent_filing_link_fields.parquet ../input/historical_parent_candidate_pairs.parquet \
	../input/historical_polygon_adjacency_pairs.parquet ../input/historical_polygon_geometry_coverage.parquet \
	../output/post_policy_filing_link_fields.parquet ../input/hdb_mappluto_site_panel.parquet \
	../input/mappluto_files.csv ../../shared/code/write_data_report.R | $(OOPR)
	$(R) $< 2010 2011 2023 2023 2025 365 30 23v3.1

../output/post_policy_filing_link_fields.parquet: construct_post_policy_parent_crosswalk.R Makefile \
	../../shared/code/source_pipeline_utils.R ../input/dob_now_new_building_initial_filings.parquet \
	../input/mappluto_appbbl_crosswalk.csv ../../shared/code/write_data_report.R | $(OOPR)
	$(R) $< 2022 2026 6 1000

../input/hdb_mappluto_site_panel.parquet: \
	../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | ../input
	ln -sf $< $@

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	ln -sf $< $@

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@

../input/mappluto_appbbl_crosswalk.csv: ../../build_hdb_mappluto_site_panel/output/mappluto_appbbl_crosswalk.csv \
	| ../input
	ln -sf $< $@

../input/historical_%.parquet: ../../construct_historical_parent_links/output/historical_%.parquet | ../input
	ln -sf $< $@

../input/%.csv: ../../parent_opportunities_manual/output/%.csv | ../input
	ln -sf $< $@

../input/%.zip: ../../fetch_mappluto_archive/output/%.zip | ../input
	ln -sf $< $@
