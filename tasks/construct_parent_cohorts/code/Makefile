include ../../shared/code/shell_functions.make

HISTORICAL_LINK_START_YEAR := 2010
HISTORICAL_COHORT_START_YEAR := 2011
HISTORICAL_END_YEAR := 2023
POST_COMPARISON_START_YEAR := 2023
POST_COHORT_YEAR := 2025
MAX_FILING_DAYS := 365
CORROBORATION_DAYS := 30
POST_GEOMETRY_VINTAGE := 23v3.1

ifneq ($(filter command,$(origin HISTORICAL_LINK_START_YEAR) $(origin HISTORICAL_COHORT_START_YEAR) $(origin HISTORICAL_END_YEAR) $(origin POST_COMPARISON_START_YEAR) $(origin POST_COHORT_YEAR) $(origin MAX_FILING_DAYS) $(origin CORROBORATION_DAYS) $(origin POST_GEOMETRY_VINTAGE)),)
$(error These fixed-name outputs use the settings recorded in this Makefile; edit those settings here so Make tracks the change)
endif
START_YEAR := 2022
END_YEAR := 2026
MIN_UNITS := 6
MAX_UNITS := 1000

ifneq ($(filter command,$(origin START_YEAR) $(origin END_YEAR) $(origin MIN_UNITS) $(origin MAX_UNITS)),)
$(error These fixed-name outputs use the settings recorded in this Makefile; edit those settings here so Make tracks the change)
endif

all: ../report/post_policy_filing_link_fields.txt ../output/post_policy_filing_link_fields.parquet \
	../report/symmetric_parent_links.txt ../report/symmetric_parent_membership.txt \
	../output/symmetric_parent_links.parquet ../output/symmetric_parent_membership.parquet

../output/symmetric_parent_links.parquet ../output/symmetric_parent_membership.parquet \
	../report/symmetric_parent_links.txt ../report/symmetric_parent_membership.txt: construct_parent_cohorts.R Makefile \
	../input/dob_now_new_building_initial_filings.parquet ../input/nyc_mappluto_23v3_1_arc_shp.zip \
	../input/pair_decisions.csv ../input/post_parent_reviews.csv ../input/unit_decisions.csv \
	../input/post_parent_filing_roles.csv ../../shared/code/source_pipeline_utils.R \
	../input/historical_parent_filing_link_fields.parquet ../input/historical_parent_candidate_pairs.parquet \
	../input/historical_polygon_adjacency_pairs.parquet ../input/historical_polygon_geometry_coverage.parquet \
	../output/post_policy_filing_link_fields.parquet ../input/hdb_mappluto_site_panel.parquet ../input/mappluto_files.csv \
	../../shared/code/write_data_report.R | ../output ../report
	$(R) $< $(HISTORICAL_LINK_START_YEAR) $(HISTORICAL_COHORT_START_YEAR) $(HISTORICAL_END_YEAR)  	$(POST_COMPARISON_START_YEAR) $(POST_COHORT_YEAR) $(MAX_FILING_DAYS) $(CORROBORATION_DAYS) $(POST_GEOMETRY_VINTAGE)

../output/post_policy_filing_link_fields.parquet ../report/post_policy_filing_link_fields.txt: \
	construct_post_policy_parent_crosswalk.R Makefile ../../shared/code/source_pipeline_utils.R \
	../input/dob_now_new_building_initial_filings.parquet ../input/mappluto_appbbl_crosswalk.csv \
	../../shared/code/write_data_report.R | ../output ../report
	$(R) $< $(START_YEAR) $(END_YEAR) $(MIN_UNITS) $(MAX_UNITS)

../input/hdb_mappluto_site_panel.parquet: ../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | \
	../input
	ln -sf $< $@

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	ln -sf $< $@

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@

../input/mappluto_appbbl_crosswalk.csv: ../../build_hdb_mappluto_site_panel/output/mappluto_appbbl_crosswalk.csv | \
	../input
	ln -sf $< $@

../input/historical_%.parquet: ../../construct_historical_parent_links/output/historical_%.parquet | ../input
	ln -sf $< $@

../input/%.csv: ../../parent_opportunities_manual/output/%.csv | ../input
	ln -sf $< $@

../input/%.zip: ../../fetch_mappluto_archive/output/%.zip | ../input
	ln -sf $< $@

link-inputs: ../input/historical_parent_filing_link_fields.parquet ../input/historical_parent_candidate_pairs.parquet \
	../input/historical_polygon_adjacency_pairs.parquet ../input/historical_polygon_geometry_coverage.parquet \
	../input/hdb_mappluto_site_panel.parquet ../input/mappluto_files.csv ../input/pair_decisions.csv \
	../input/unit_decisions.csv ../input/post_parent_reviews.csv ../input/post_parent_filing_roles.csv \
	../input/dob_now_new_building_initial_filings.parquet ../input/nyc_mappluto_23v3_1_arc_shp.zip \
	../input/mappluto_appbbl_crosswalk.csv

include ../../shared/code/generic.make
