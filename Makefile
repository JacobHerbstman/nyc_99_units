include tasks/shared/code/shell_functions.make

.DEFAULT_GOAL := all

TASKS := analyze_borough_bunching build_estimation_panels build_hdb_mappluto_site_panel \
	build_parent_site_characteristics classify_parent_485x_exposure construct_historical_parent_links \
	construct_parent_cohorts fetch_dcp_housing_database fetch_dob_now_new_building_filings \
	fetch_hpd_485x_registrations fetch_mappluto_archive fetch_nyc_borough_boundaries \
	link_hpd_485x_registrations parent_opportunities_manual plot_bunching stage_dcp_housing_database \
	stage_dob_now_new_building_filings stage_mappluto_lots

all: plot_bunching analyze_borough_bunching task_graph.svg
data: build_estimation_panels
plots: plot_bunching
maps: analyze_borough_bunching

analyze_borough_bunching: build_estimation_panels fetch_nyc_borough_boundaries stage_dcp_housing_database \
	stage_dob_now_new_building_filings
	$(MAKE) -C tasks/analyze_borough_bunching/code

build_estimation_panels: build_parent_site_characteristics classify_parent_485x_exposure construct_parent_cohorts \
	link_hpd_485x_registrations
	$(MAKE) -C tasks/build_estimation_panels/code

build_hdb_mappluto_site_panel: fetch_mappluto_archive stage_dcp_housing_database stage_mappluto_lots
	$(MAKE) -C tasks/build_hdb_mappluto_site_panel/code

build_parent_site_characteristics: build_hdb_mappluto_site_panel construct_parent_cohorts stage_mappluto_lots
	$(MAKE) -C tasks/build_parent_site_characteristics/code

classify_parent_485x_exposure: construct_historical_parent_links construct_parent_cohorts link_hpd_485x_registrations \
	stage_dcp_housing_database stage_dob_now_new_building_filings
	$(MAKE) -C tasks/classify_parent_485x_exposure/code

construct_historical_parent_links: build_hdb_mappluto_site_panel fetch_mappluto_archive parent_opportunities_manual \
	stage_dcp_housing_database stage_dob_now_new_building_filings
	$(MAKE) -C tasks/construct_historical_parent_links/code

construct_parent_cohorts: build_hdb_mappluto_site_panel construct_historical_parent_links fetch_mappluto_archive \
	parent_opportunities_manual stage_dob_now_new_building_filings
	$(MAKE) -C tasks/construct_parent_cohorts/code

fetch_dcp_housing_database:
	$(MAKE) -C tasks/fetch_dcp_housing_database/code

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

logbook: all
	$(MAKE) -C tasks/audits/audit_acs_construction_wages/code
	$(MAKE) -C tasks/audits/audit_qcew_construction_wages/code
	$(MAKE) -C tasks/audits/audit_lodes_construction_wages/code
	$(MAKE) -C tasks/audits/audit_estimation_parent_links/code
	$(MAKE) -C tasks/audits/audit_scale_shape_splitting/code
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

.PHONY: all data plots maps paper logbook framework-writeup setup-environment $(TASKS)
