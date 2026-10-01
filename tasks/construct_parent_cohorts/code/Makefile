include ../../shared/code/shell_functions.make

all: ../output/post_policy_filing_link_fields.parquet ../output/owner_proximity_links.parquet \
	../output/symmetric_parent_membership.parquet ../output/symmetric_parent_links.parquet

include ../../shared/code/generic.make

../output/post_policy_filing_link_fields.parquet: construct_post_policy_parent_crosswalk.R \
	../input/dob_now_new_building_initial_filings.parquet ../input/dcp_housing_database_project_level_25q4.parquet \
	../input/mappluto_appbbl_crosswalk.csv Makefile | $(OOPR)
	$(R) $<

../output/owner_proximity_links.parquet: construct_owner_proximity_links.R \
	../input/historical_parent_filing_link_fields.parquet ../output/post_policy_filing_link_fields.parquet \
	../input/dob_now_new_building_initial_filings.parquet ../input/dob_bis_nb_initial_filings.csv \
	../input/dcp_housing_database_project_level_raw_23q4.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet Makefile | $(OOPR)
	$(R) $<

../output/symmetric_parent_membership.parquet ../output/symmetric_parent_links.parquet: construct_parent_cohorts.R \
	../input/historical_parent_filing_link_fields.parquet ../input/historical_parent_pairs.parquet \
	../output/post_policy_filing_link_fields.parquet ../output/owner_proximity_links.parquet \
	../input/nyc_mappluto_23v3_1_arc_shp.zip ../input/dob_now_new_building_initial_filings.parquet \
	../input/dcp_housing_database_project_level_23q4.parquet ../input/dcp_housing_database_project_level_25q4.parquet \
	../input/pair_decisions.csv ../input/post_parent_reviews.csv ../input/post_parent_filing_roles.csv \
	../input/historical_filing_roles.csv ../input/unit_decisions.csv Makefile | $(OOPR)
	$(R) $<

../input/historical_%.parquet: ../../construct_historical_parent_links/output/historical_%.parquet | ../input
	ln -sf $< $@

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@

../input/dob_bis_nb_initial_filings.csv: \
	../../fetch_dob_bis_job_filings/output/dob_bis_job_filings_20260923_nb_initial_filings.csv | ../input
	ln -sf $< $@

../input/dcp_housing_database_project_level_%.parquet: \
	../../stage_dcp_housing_database/output/dcp_housing_database_project_level_%.parquet | ../input
	ln -sf $< $@

../input/mappluto_appbbl_crosswalk.csv: ../../build_hdb_mappluto_site_panel/output/mappluto_appbbl_crosswalk.csv \
	| ../input
	ln -sf $< $@

../input/nyc_mappluto_23v3_1_arc_shp.zip: ../../fetch_mappluto_archive/output/nyc_mappluto_23v3_1_arc_shp.zip | ../input
	ln -sf $< $@

../input/%.csv: ../../parent_opportunities_manual/output/%.csv | ../input
	ln -sf $< $@
