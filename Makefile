include tasks/shared/code/shell_functions.make

.DEFAULT_GOAL := all

TASKS := analyze_borough_bunching build_estimation_panels build_hdb_mappluto_site_panel \
	build_parent_site_characteristics classify_parent_485x_exposure construct_historical_parent_links \
	construct_parent_cohorts fetch_dcp_housing_database fetch_dob_now_new_building_filings \
	fetch_hpd_485x_registrations fetch_mappluto_archive fetch_nyc_borough_boundaries fetch_dof_tax_map_history \
	link_hpd_485x_registrations parent_opportunities_manual plot_bunching stage_dcp_housing_database \
	stage_dob_now_new_building_filings stage_mappluto_lots

all: plot_bunching analyze_borough_bunching task_graph.svg
data: build_estimation_panels
plots: plot_bunching
maps: analyze_borough_bunching

dof-parcel-audit: data fetch_dof_tax_map_history
	$(MAKE) -C tasks/audits/audit_hdb_mappluto_condo_recovery/code ../output/dof_parent_parcels.parquet \
		../output/dof_parent_coverage.csv ../output/dof_coverage_summary.csv

dof-subset-review: dof-parcel-audit
	$(MAKE) -C tasks/audits/download_parent_review_documents/code \
		dof_subset_validation_2026-09-15/assessments.json dof_subset_validation_2026-09-15/assessment_count.json \
		dof_subset_validation_2026-09-15/assessment_schema.json ../output/dof_assessment_layout.xlsx \
		../output/noble_cb1_notice_2026-06-09.pdf ../output/sackett_property_2022-07-06.pdf \
		../output/sackett_project_2022-07-06.pdf ../output/dof_map_30042620220913162303.pdf \
		../output/greenpoint_boundary_2019-11-25.pdf ../output/sackett_irm_2022-03-04.pdf \
		../output/gowanus_existing_conditions_2024-03.pdf ../output/dof_subset_godwin_companion.geojson
	$(MAKE) -C tasks/audits/audit_hdb_mappluto_condo_recovery/code ../output/dof_subset_comparison.csv \
		../output/dof_subset_summary.csv ../output/dof_subset_footprints.pdf \
		../output/dof_subset_assessment_history.csv ../output/dof_subset_lot_checks.csv ../output/dof_subset_waterfront_areas.csv

dof-geometry-review: dof-parcel-audit
	$(MAKE) -C tasks/audits/audit_hdb_mappluto_condo_recovery/code ../output/dof_geometry_lots.parquet \
		../output/dof_geometry_overlaps.parquet ../output/dof_geometry_comparison.csv ../output/dof_geometry_summary.csv \
		../output/dof_all_parent_geometry.csv ../output/dof_all_parent_overlaps.parquet \
		../output/dof_geometry_overview.pdf ../output/dof_geometry_overview.png ../output/dof_geometry_footprints.pdf
	$(MAKE) -C tasks/audits/audit_hdb_mappluto_condo_recovery/code ../output/dof_filing_map_lots.parquet \
		../output/dof_filing_map_coverage.csv ../output/dof_filing_map_matches.csv ../output/dof_filing_map_footprints.pdf
	$(MAKE) -C tasks/audits/download_parent_review_documents/code ../output/flatbush_ida_minutes_2020-05-12.pdf \
		../output/flatbush_tax_map_2008.pdf ../output/flatbush_tax_map_2020.pdf
	$(MAKE) -C tasks/audits/audit_hdb_mappluto_condo_recovery/code ../output/bis_filing_sites.csv ../output/bis_parent_site_comparison.csv

pure-notch-pilot: data
	$(MAKE) -C tasks/audits/audit_scale_shape_splitting/code ../output/calibration_weights.csv \
		../output/calibration_summary.csv ../output/bootstrap_intervals.csv ../output/bootstrap_run_summary.csv
	$(MAKE) -C tasks/audits/fit_pure_notch_pilot/code

flatbush-floor-review: data
	$(MAKE) -C tasks/audits/download_parent_review_documents/code -f flatbush_floor.make
	$(MAKE) -C tasks/audits/audit_hdb_mappluto_condo_recovery/code -f flatbush_floor.make

five-floor-review: dof-geometry-review
	$(MAKE) -C tasks/audits/download_parent_review_documents/code -f five_floor.make
	$(MAKE) -C tasks/audits/audit_hdb_mappluto_condo_recovery/code -f five_floor.make

dof-site-review: dof-geometry-review
	$(MAKE) -C tasks/audits/download_parent_review_documents/code -f next_ten.make
	$(MAKE) -C tasks/audits/download_parent_review_documents/code -f reopened_batch.make
	$(MAKE) -C tasks/audits/audit_hdb_mappluto_condo_recovery/code -f queued_followup.make
	$(MAKE) -C tasks/audits/download_parent_review_documents/code \
		../output/bedford_beverly_recorded_ee_2024-12-20.pdf ../output/bedford_beverly_rir_2023-10-26.pdf \
		../output/nyc_cb1_2022-02-08_dupont_cleanup_notice.pdf ../output/dof_map_30513520240607105717.pdf \
		../output/motto_dec_final_engineering_report_appendix_d.pdf
	$(MAKE) -C tasks/audits/audit_hdb_mappluto_condo_recovery/code ../output/parent_site_lot_envelopes.parquet \
		../output/parent_site_other_filings.csv ../output/parent_site_scope.csv ../output/parent_site_scope_summary.csv \
		../output/hdb_unit_fallback.csv ../output/prepolicy_old_review_queue.csv ../output/prepolicy_current_review_queue.csv

analyze_borough_bunching: build_estimation_panels fetch_nyc_borough_boundaries stage_dcp_housing_database \
	stage_dob_now_new_building_filings
	$(MAKE) -C tasks/analyze_borough_bunching/code

build_estimation_panels: build_parent_site_characteristics classify_parent_485x_exposure construct_parent_cohorts \
	link_hpd_485x_registrations
	$(MAKE) -C tasks/build_estimation_panels/code

build_hdb_mappluto_site_panel: fetch_mappluto_archive stage_dcp_housing_database stage_mappluto_lots
	$(MAKE) -C tasks/build_hdb_mappluto_site_panel/code

build_parent_site_characteristics: build_hdb_mappluto_site_panel construct_parent_cohorts stage_mappluto_lots \
	stage_dob_now_new_building_filings parent_opportunities_manual
	$(MAKE) -C tasks/build_parent_site_characteristics/code

classify_parent_485x_exposure: construct_historical_parent_links construct_parent_cohorts link_hpd_485x_registrations \
	stage_dcp_housing_database stage_dob_now_new_building_filings
	$(MAKE) -C tasks/classify_parent_485x_exposure/code

construct_historical_parent_links: build_hdb_mappluto_site_panel fetch_mappluto_archive parent_opportunities_manual \
	stage_dcp_housing_database
	$(MAKE) -C tasks/construct_historical_parent_links/code

construct_parent_cohorts: build_hdb_mappluto_site_panel construct_historical_parent_links fetch_mappluto_archive \
	parent_opportunities_manual stage_dob_now_new_building_filings stage_dcp_housing_database
	$(MAKE) -C tasks/construct_parent_cohorts/code

fetch_dcp_housing_database:
	$(MAKE) -C tasks/fetch_dcp_housing_database/code

fetch_dof_tax_map_history:
	$(MAKE) -C tasks/fetch_dof_tax_map_history/code

fetch_dob_now_new_building_filings:
	$(MAKE) -C tasks/fetch_dob_now_new_building_filings/code

fetch_hpd_485x_registrations:
	$(MAKE) -C tasks/fetch_hpd_485x_registrations/code

fetch_mappluto_archive:
	$(MAKE) -C tasks/fetch_mappluto_archive/code

fetch_nyc_borough_boundaries:
	$(MAKE) -C tasks/fetch_nyc_borough_boundaries/code

link_hpd_485x_registrations: fetch_hpd_485x_registrations stage_dob_now_new_building_filings
	$(MAKE) -C tasks/link_hpd_485x_registrations/code

parent_opportunities_manual:
	$(MAKE) -C tasks/parent_opportunities_manual/code

plot_bunching: build_estimation_panels
	$(MAKE) -C tasks/plot_bunching/code

stage_dcp_housing_database: fetch_dcp_housing_database
	$(MAKE) -C tasks/stage_dcp_housing_database/code

stage_dob_now_new_building_filings: fetch_dob_now_new_building_filings
	$(MAKE) -C tasks/stage_dob_now_new_building_filings/code

stage_mappluto_lots: fetch_mappluto_archive
	$(MAKE) -C tasks/stage_mappluto_lots/code

setup-environment:
	$(MAKE) -C tasks/setup_environment/code

paper: all
	$(MAKE) -C paper

logbook:
	$(MAKE) -C logbook

framework-writeup: plots
	$(MAKE) -C tasks/audits/audit_scale_shape_splitting/code
	$(MAKE) framework_writeup.pdf

framework_writeup.pdf: framework_writeup.tex Makefile \
	tasks/audits/audit_scale_shape_splitting/temp/scale_shape_splitting_figure_guide_values.tex
	pdflatex -interaction=nonstopmode -halt-on-error $<
	pdflatex -interaction=nonstopmode -halt-on-error $<

task_graph.svg: tasks/shared/code/draw_task_graph.py Makefile \
	$(foreach task,$(TASKS),tasks/$(task)/code/Makefile)
	python3 tasks/shared/code/draw_task_graph.py

.PHONY: all data plots maps dof-parcel-audit dof-subset-review dof-geometry-review dof-site-review pure-notch-pilot flatbush-floor-review five-floor-review paper logbook framework-writeup setup-environment $(TASKS)
