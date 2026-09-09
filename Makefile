SHELL := /bin/bash
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.NOTPARALLEL:

.PHONY: all setup-environment source-registry paper framework-writeup empirics check-empirics

all: framework-writeup empirics task_graph.svg

setup-environment:
	$(MAKE) -C tasks/setup_environment/code

source-registry:
	$(MAKE) -C tasks/source_registry/code

paper:
	$(MAKE) -C paper

empirics: tasks/analyze_485x_scale_shape_splitting/output/pdf/scale_shape_splitting_figure_guide.pdf

tasks/analyze_485x_scale_shape_splitting/output/pdf/scale_shape_splitting_figure_guide.pdf: check-empirics ;

framework-writeup: framework_writeup.pdf

framework_writeup.pdf: framework_writeup.tex Makefile \
	tasks/analyze_485x_scale_shape_splitting/temp/scale_shape_splitting_figure_guide_values.tex
	pdflatex -interaction=nonstopmode -halt-on-error framework_writeup.tex
	pdflatex -interaction=nonstopmode -halt-on-error framework_writeup.tex
	pdflatex -interaction=nonstopmode -halt-on-error framework_writeup.tex

tasks/analyze_485x_scale_shape_splitting/temp/scale_shape_splitting_figure_guide_values.tex: check-empirics ;

check-empirics:
	@$(MAKE) --silent -C tasks/analyze_485x_scale_shape_splitting/code all


task_graph.svg: tasks/shared/code/draw_task_graph.py \
	tasks/parent_opportunities_manual/code/Makefile \
	tasks/analyze_485x_scale_shape_splitting/code/Makefile \
	tasks/analyze_borough_bunching/code/Makefile \
	tasks/analyze_parent_unit_distribution/code/Makefile \
	tasks/build_hdb_mappluto_site_panel/code/Makefile \
	tasks/build_mappluto_appbbl_crosswalk/code/Makefile \
	tasks/build_parent_485x_exposure_universe/code/Makefile \
	tasks/build_parent_site_characteristics/code/Makefile \
	tasks/classify_parent_485x_exposure/code/Makefile \
	tasks/construct_historical_parent_adjacency/code/Makefile \
	tasks/construct_historical_parent_links/code/Makefile \
	tasks/construct_parent_cohorts/code/Makefile \
	tasks/construct_post_policy_parent_crosswalk/code/Makefile \
	tasks/define_mappluto_release_calendar/code/Makefile \
	tasks/fetch_dcp_housing_database/code/Makefile \
	tasks/fetch_dob_now_new_building_filings/code/Makefile \
	tasks/fetch_hpd_485x_registrations/code/Makefile \
	tasks/fetch_mappluto_archive/code/Makefile \
	tasks/fetch_nyc_borough_boundaries/code/Makefile \
	tasks/link_hpd_485x_registrations/code/Makefile \
	tasks/load_dcp_housing_database_raw/code/Makefile \
	tasks/load_mappluto_raw/code/Makefile \
	tasks/load_nys_ag_offering_plan_matches/code/Makefile \
	tasks/setup_environment/code/Makefile \
	tasks/source_registry/code/Makefile \
	tasks/stage_dcp_housing_database/code/Makefile \
	tasks/stage_dob_now_new_building_filings/code/Makefile \
	tasks/stage_hpd_485x_registrations/code/Makefile \
	tasks/stage_mappluto_lots/code/Makefile
	python3 tasks/shared/code/draw_task_graph.py
