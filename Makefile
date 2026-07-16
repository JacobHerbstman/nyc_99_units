SHELL := /bin/bash
.DEFAULT_GOAL := all

.PHONY: all setup-environment source-registry paper framework-writeup \
	check-bunching check-parent-model check-developer-responses

all: paper

setup-environment:
	$(MAKE) -C tasks/setup_environment/code

source-registry:
	$(MAKE) -C tasks/source_registry/code

paper:
	$(MAKE) -C paper

framework-writeup: framework_writeup.pdf

framework_writeup.pdf: framework_writeup.tex \
	tasks/summarize_hdb_unit_bunching/output/hdb_unit_bunching_histogram.pdf \
	tasks/estimate_parent_no_notch_model/output/enhanced_parent_2025_counterfactual.pdf \
	tasks/summarize_developer_responses/output/developer_response_provisional_site_construction_area_vs_units.pdf \
	tasks/summarize_developer_responses/output/developer_response_provisional_site_construction_square_feet_per_unit.pdf \
	tasks/summarize_developer_responses/output/developer_response_provisional_site_building_application_counts.pdf
	pdflatex -interaction=nonstopmode -halt-on-error framework_writeup.tex
	pdflatex -interaction=nonstopmode -halt-on-error framework_writeup.tex

tasks/summarize_hdb_unit_bunching/output/hdb_unit_bunching_histogram.pdf: | check-bunching
	@test -e "$@"

tasks/estimate_parent_no_notch_model/output/enhanced_parent_2025_counterfactual.pdf: | check-parent-model
	@test -e "$@"

tasks/summarize_developer_responses/output/developer_response_provisional_site_construction_area_vs_units.pdf \
tasks/summarize_developer_responses/output/developer_response_provisional_site_construction_square_feet_per_unit.pdf \
tasks/summarize_developer_responses/output/developer_response_provisional_site_building_application_counts.pdf: | check-developer-responses
	@test -e "$@"

check-bunching:
	$(MAKE) -C tasks/summarize_hdb_unit_bunching/code ../output/hdb_unit_bunching_histogram.pdf

check-parent-model:
	$(MAKE) -C tasks/estimate_parent_no_notch_model/code ../output/enhanced_parent_2025_counterfactual.pdf

check-developer-responses:
	$(MAKE) -C tasks/summarize_developer_responses/code \
		../output/developer_response_provisional_site_construction_area_vs_units.pdf \
		../output/developer_response_provisional_site_construction_square_feet_per_unit.pdf \
		../output/developer_response_provisional_site_building_application_counts.pdf
