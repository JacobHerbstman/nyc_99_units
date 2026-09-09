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

all: ../output/symmetric_parent_membership.parquet ../output/symmetric_parent_links.parquet \
	../report/symmetric_parent_links.txt \
	../report/symmetric_parent_membership.txt

../output/symmetric_parent_membership.parquet: construct_parent_cohorts.R Makefile \
	../input/nyc_mappluto_23v3_1_arc_shp.zip historical_parent_link_reviews.csv post_parent_reviews.csv \
	post_parent_link_reviews.csv post_parent_filing_roles.csv ../../shared/code/source_pipeline_utils.R \
	../input/historical_parent_filing_link_fields.parquet ../input/historical_parent_candidate_pairs.parquet \
	../input/historical_polygon_adjacency_pairs.parquet ../input/historical_polygon_geometry_coverage.parquet \
	../input/post_policy_filing_link_fields.parquet ../input/hdb_mappluto_site_panel.parquet \
	../input/mappluto_files.csv \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $< $(HISTORICAL_LINK_START_YEAR) \
		$(HISTORICAL_COHORT_START_YEAR) $(HISTORICAL_END_YEAR) \
		$(POST_COMPARISON_START_YEAR) $(POST_COHORT_YEAR) \
		$(MAX_FILING_DAYS) $(CORROBORATION_DAYS) \
		$(POST_GEOMETRY_VINTAGE)

../output/symmetric_parent_links.parquet: ../output/symmetric_parent_membership.parquet
	$(MAKE) -W construct_parent_cohorts.R all


../report/symmetric_parent_links.txt: report_data.R ../../shared/code/write_data_report.R ../output/symmetric_parent_links.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< symmetric_parent_links

../report/symmetric_parent_membership.txt: report_data.R ../../shared/code/write_data_report.R ../output/symmetric_parent_membership.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< symmetric_parent_membership


../input/historical_parent_filing_link_fields.parquet: ../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_candidate_pairs.parquet: ../../construct_historical_parent_links/output/historical_parent_candidate_pairs.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_polygon_adjacency_pairs.parquet: ../../construct_historical_parent_adjacency/output/historical_polygon_adjacency_pairs.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_polygon_geometry_coverage.parquet: ../../construct_historical_parent_adjacency/output/historical_polygon_geometry_coverage.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/post_policy_filing_link_fields.parquet: ../../construct_post_policy_parent_crosswalk/output/post_policy_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/hdb_mappluto_site_panel.parquet: ../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/mappluto_files.csv: ../../fetch_mappluto_archive/output/mappluto_files.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/historical_parent_filing_link_fields.parquet \
	../input/historical_parent_candidate_pairs.parquet \
	../input/historical_polygon_adjacency_pairs.parquet \
	../input/historical_polygon_geometry_coverage.parquet \
	../input/post_policy_filing_link_fields.parquet \
	../input/hdb_mappluto_site_panel.parquet \
	../input/mappluto_files.csv


../input/nyc_mappluto_23v3_1_arc_shp.zip: ../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v3.1_nyc_mappluto_23v3_1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet \
	../../construct_historical_parent_links/output/historical_parent_candidate_pairs.parquet: check-construct_historical_parent_links ;

.PHONY: check-construct_historical_parent_links

check-construct_historical_parent_links:
	$(MAKE) -C ../../construct_historical_parent_links/code all ../output/historical_parent_filing_link_fields.parquet ../output/historical_parent_candidate_pairs.parquet

../../construct_historical_parent_adjacency/output/historical_polygon_adjacency_pairs.parquet \
	../../construct_historical_parent_adjacency/output/historical_polygon_geometry_coverage.parquet: check-construct_historical_parent_adjacency ;

.PHONY: check-construct_historical_parent_adjacency

check-construct_historical_parent_adjacency:
	$(MAKE) -C ../../construct_historical_parent_adjacency/code all ../output/historical_polygon_adjacency_pairs.parquet ../output/historical_polygon_geometry_coverage.parquet

../../construct_post_policy_parent_crosswalk/output/post_policy_filing_link_fields.parquet: check-construct_post_policy_parent_crosswalk ;

.PHONY: check-construct_post_policy_parent_crosswalk

check-construct_post_policy_parent_crosswalk:
	$(MAKE) -C ../../construct_post_policy_parent_crosswalk/code all ../output/post_policy_filing_link_fields.parquet

../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet: check-build_hdb_mappluto_site_panel ;

.PHONY: check-build_hdb_mappluto_site_panel

check-build_hdb_mappluto_site_panel:
	$(MAKE) -C ../../build_hdb_mappluto_site_panel/code all ../output/hdb_mappluto_site_panel.parquet

../../fetch_mappluto_archive/output/mappluto_files.csv \
	../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v3.1_nyc_mappluto_23v3_1_arc_shp.zip: check-fetch_mappluto_archive ;

.PHONY: check-fetch_mappluto_archive

check-fetch_mappluto_archive:
	$(MAKE) -C ../../fetch_mappluto_archive/code all ../output/mappluto_files.csv ../output/dcp_mappluto_archive_23v3.1_nyc_mappluto_23v3_1_arc_shp.zip

include ../../shared/code/generic.make
