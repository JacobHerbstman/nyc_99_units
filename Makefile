SHELL := /bin/bash
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.NOTPARALLEL:

.PHONY: all data plots maps setup-environment paper framework-writeup
all: tasks/plot_bunching/output/pdf/main_project_plots.pdf \
	tasks/analyze_borough_bunching/output/borough_bunching.pdf task_graph.svg

data:
	$(MAKE) -C tasks/build_estimation_panels/code

plots: tasks/plot_bunching/output/pdf/main_project_plots.pdf
maps: tasks/analyze_borough_bunching/output/borough_bunching.pdf

tasks/plot_bunching/output/pdf/main_project_plots.pdf: check-plots ;
.PHONY: check-plots
check-plots:
	$(MAKE) -C tasks/plot_bunching/code all

tasks/analyze_borough_bunching/output/borough_bunching.pdf: check-maps ;
.PHONY: check-maps
check-maps:
	$(MAKE) -C tasks/analyze_borough_bunching/code all

setup-environment:
	$(MAKE) -C tasks/setup_environment/code

paper:
	$(MAKE) -C paper

framework-writeup: framework_writeup.pdf

framework_writeup.pdf: framework_writeup.tex Makefile tasks/audits/audit_scale_shape_splitting/temp/scale_shape_splitting_figure_guide_values.tex
	pdflatex -interaction=nonstopmode -halt-on-error framework_writeup.tex
	pdflatex -interaction=nonstopmode -halt-on-error framework_writeup.tex
	pdflatex -interaction=nonstopmode -halt-on-error framework_writeup.tex

tasks/audits/audit_scale_shape_splitting/temp/scale_shape_splitting_figure_guide_values.tex: check-framework-values ;
.PHONY: check-framework-values
check-framework-values:
	$(MAKE) -C tasks/audits/audit_scale_shape_splitting/code all

task_graph.svg: tasks/shared/code/draw_task_graph.py \
	tasks/analyze_borough_bunching/code/Makefile \
	tasks/build_estimation_panels/code/Makefile \
	tasks/build_hdb_mappluto_site_panel/code/Makefile \
	tasks/build_parent_site_characteristics/code/Makefile \
	tasks/classify_parent_485x_exposure/code/Makefile \
	tasks/construct_historical_parent_links/code/Makefile \
	tasks/construct_parent_cohorts/code/Makefile \
	tasks/fetch_dcp_housing_database/code/Makefile \
	tasks/fetch_dob_now_new_building_filings/code/Makefile \
	tasks/fetch_hpd_485x_registrations/code/Makefile \
	tasks/fetch_mappluto_archive/code/Makefile \
	tasks/fetch_nyc_borough_boundaries/code/Makefile \
	tasks/link_hpd_485x_registrations/code/Makefile \
	tasks/parent_opportunities_manual/code/Makefile \
	tasks/plot_bunching/code/Makefile \
	tasks/setup_environment/code/Makefile \
	tasks/stage_dcp_housing_database/code/Makefile \
	tasks/stage_dob_now_new_building_filings/code/Makefile \
	tasks/stage_mappluto_lots/code/Makefile
	python3 tasks/shared/code/draw_task_graph.py
