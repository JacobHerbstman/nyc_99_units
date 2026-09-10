include ../../../shared/code/shell_functions.make

NEAR_METRES := 200
NEAR_DAYS := 365

ifneq ($(filter command,$(origin NEAR_METRES) $(origin NEAR_DAYS)),)
$(error Edit the recorded settings here for these fixed-name outputs)
endif

all: ../output/dob_unit_filings.csv ../output/dob_unit_parents.csv ../report/dob_unit_filings.txt ../report/dob_unit_parents.txt ../output/refilings.csv ../report/refilings.txt ../output/companion_link_trace.csv ../report/companion_link_trace.txt ../output/third_avenue_plan.png ../output/parent_constituents.csv ../output/parent_casebook.md ../output/nearby_filings.csv ../report/parent_constituents.txt ../report/nearby_filings.txt

../output/dob_unit_filings.csv: compare_unit_sources.R ../input/parent_opportunity_panel.parquet ../input/symmetric_parent_membership.parquet ../input/dob_now_new_building_initial_filings.parquet ../input/dcp_housing_database_project_level_raw_25q4.parquet | ../output
	$(R) $<

../output/dob_unit_parents.csv: ../output/dob_unit_filings.csv
	$(RECOVER) -W compare_unit_sources.R all

../report/dob_unit_filings.txt: report_data.R ../../../shared/code/write_data_report.R ../output/dob_unit_filings.csv | ../report
	$(R) $< dob_unit_filings

../report/dob_unit_parents.txt: report_data.R ../../../shared/code/write_data_report.R ../output/dob_unit_parents.csv | ../report
	$(R) $< dob_unit_parents

../output/refilings.csv: review_refilings.R ../input/symmetric_parent_membership.parquet ../input/dob_now_new_building_initial_filings.parquet | ../output
	$(R) $<

../report/refilings.txt: report_data.R ../../../shared/code/write_data_report.R ../output/refilings.csv | ../report
	$(R) $< refilings

../output/companion_link_trace.csv: trace_companions.R Makefile ../input/symmetric_parent_membership.parquet ../input/post_policy_filing_link_fields.parquet ../input/historical_parent_filing_link_fields.parquet ../input/historical_parent_candidate_pairs.parquet ../input/hdb_mappluto_site_panel.parquet ../input/symmetric_parent_links.parquet ../input/nyc_mappluto_23v3_1_arc_shp.zip | ../output
	$(R) $<

../report/companion_link_trace.txt: report_data.R ../../../shared/code/write_data_report.R ../output/companion_link_trace.csv | ../report
	$(R) $< companions

../output/third_avenue_plan.png: ../input/4121_third_rawp_2025-10-01.pdf Makefile | ../output
	pdftoppm -f 77 -l 77 -singlefile -scale-to 2600 -png $< ../output/third_avenue_plan

../output/parent_constituents.csv: review_parents.R Makefile parent_evidence.csv ../output/refilings.csv ../report/ten_case_deep_review.md ../output/nearby_filings.csv \
	../input/parent_opportunity_panel.parquet \
	../input/symmetric_parent_membership.parquet \
	../input/symmetric_parent_links.parquet \
	../input/historical_parent_filing_link_fields.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/dob_now_new_building_filings.parquet | ../output
	$(R) $<

../output/parent_casebook.md: ../output/parent_constituents.csv
	$(RECOVER) -W review_parents.R all

../output/nearby_filings.csv: screen_neighbors.R Makefile neighbor_evidence.csv ../input/pair_decisions.csv ../input/parent_opportunity_panel.parquet ../input/symmetric_parent_membership.parquet ../input/dcp_housing_database_project_level_raw_25q4.parquet ../input/dob_now_new_building_initial_filings.parquet ../input/historical_parent_filing_link_fields.parquet | ../output
	$(R) $< $(NEAR_METRES) $(NEAR_DAYS)

../report/parent_constituents.txt: report_data.R ../../../shared/code/write_data_report.R ../output/parent_constituents.csv | ../report
	$(R) $< constituents

../report/nearby_filings.txt: report_data.R ../../../shared/code/write_data_report.R ../output/nearby_filings.csv | ../report
	$(R) $< neighbors

../input/parent_opportunity_panel.parquet: ../../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_membership.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/symmetric_parent_links.parquet: ../../../construct_parent_cohorts/output/symmetric_parent_links.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/historical_parent_filing_link_fields.parquet: ../../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_housing_database_project_level_raw_25q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/pair_decisions.csv ../input/post_policy_filing_link_fields.parquet ../input/historical_parent_candidate_pairs.parquet ../input/hdb_mappluto_site_panel.parquet ../input/nyc_mappluto_23v3_1_arc_shp.zip ../input/4121_third_rawp_2025-10-01.pdf ../input/parent_opportunity_panel.parquet ../input/symmetric_parent_membership.parquet ../input/symmetric_parent_links.parquet ../input/historical_parent_filing_link_fields.parquet ../input/dcp_housing_database_project_level_raw_25q4.parquet ../input/dob_now_new_building_initial_filings.parquet ../input/dob_now_new_building_filings.parquet

../../../build_estimation_panels/output/parent_opportunity_panel.parquet: check-build_estimation_panels ;

.PHONY: check-build_estimation_panels
check-build_estimation_panels:
	$(MAKE) -C ../../../build_estimation_panels/code ../output/parent_opportunity_panel.parquet ../report/parent_opportunity_panel.txt ../report/constituent_filing_panel.txt

../../../construct_parent_cohorts/output/symmetric_parent_membership.parquet ../../../construct_parent_cohorts/output/symmetric_parent_links.parquet: check-construct_parent_cohorts ;

.PHONY: check-construct_parent_cohorts
check-construct_parent_cohorts:
	$(MAKE) -C ../../../construct_parent_cohorts/code all ../output/symmetric_parent_membership.parquet ../output/symmetric_parent_links.parquet

../../../construct_historical_parent_links/output/historical_parent_filing_link_fields.parquet: check-construct_historical_parent_links ;

.PHONY: check-construct_historical_parent_links
check-construct_historical_parent_links:
	$(MAKE) -C ../../../construct_historical_parent_links/code all ../output/historical_parent_filing_link_fields.parquet

../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_25q4.parquet: check-stage_dcp_housing_database ;

.PHONY: check-stage_dcp_housing_database
check-stage_dcp_housing_database:
	$(MAKE) -C ../../../stage_dcp_housing_database/code all ../output/dcp_housing_database_project_level_raw_25q4.parquet

../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_filings.parquet: check-stage_dob_now_new_building_filings ;

.PHONY: check-stage_dob_now_new_building_filings
check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet ../output/dob_now_new_building_filings.parquet

../input/post_policy_filing_link_fields.parquet: ../../../construct_parent_cohorts/output/post_policy_filing_link_fields.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../../construct_parent_cohorts/output/post_policy_filing_link_fields.parquet: check-construct_parent_cohorts ;

.PHONY: check-construct_parent_cohorts

../input/historical_parent_candidate_pairs.parquet: ../../../construct_historical_parent_links/output/historical_parent_candidate_pairs.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../../construct_historical_parent_links/output/historical_parent_candidate_pairs.parquet: check-construct_historical_parent_links ;

../input/hdb_mappluto_site_panel.parquet: ../../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../../build_hdb_mappluto_site_panel/output/hdb_mappluto_site_panel.parquet: check-build_hdb_mappluto_site_panel ;

.PHONY: check-build_hdb_mappluto_site_panel
check-build_hdb_mappluto_site_panel:
	$(MAKE) -C ../../../build_hdb_mappluto_site_panel/code all ../output/hdb_mappluto_site_panel.parquet

../input/nyc_mappluto_23v3_1_arc_shp.zip: ../../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v3.1_nyc_mappluto_23v3_1_arc_shp.zip | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../../fetch_mappluto_archive/output/dcp_mappluto_archive_23v3.1_nyc_mappluto_23v3_1_arc_shp.zip: check-fetch_mappluto_archive ;

.PHONY: check-fetch_mappluto_archive
check-fetch_mappluto_archive:
	$(MAKE) -C ../../../fetch_mappluto_archive/code all ../output/dcp_mappluto_archive_23v3.1_nyc_mappluto_23v3_1_arc_shp.zip

../input/4121_third_rawp_2025-10-01.pdf: ../../download_parent_review_documents/output/4121_third_rawp_2025-10-01.pdf | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../download_parent_review_documents/output/4121_third_rawp_2025-10-01.pdf: check-audits-download_parent_review_documents ;

.PHONY: check-audits-download_parent_review_documents
check-audits-download_parent_review_documents:
	$(MAKE) -C ../../download_parent_review_documents/code all ../output/4121_third_rawp_2025-10-01.pdf

../input/pair_decisions.csv: ../../../parent_opportunities_manual/output/pair_decisions.csv | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

include ../../../shared/code/generic.make
