SHELL := bash

HIST_PRE_START_YEAR := 2010
DESIGN_PRE_START_YEAR := 2021
PRE_END_YEAR := 2023
POST_YEAR := 2025
MIN_UNITS := 50
DESIGN_MAX_UNITS := 150
SITE_PLOT_MAX_UNITS := 400
HIST_BIN_WIDTH := 5

all: ../output/developer_response_provisional_site_panel.parquet \
	../output/developer_response_application_panel.parquet \
	../output/developer_response_hdb_dob_join_qc.csv \
	../output/developer_response_site_definition_qc.csv \
	../output/developer_response_area_field_coverage.csv \
	../output/developer_response_design_summary.csv \
	../output/developer_response_exact_99_site_clusters.csv \
	../output/developer_response_provisional_site_unit_histogram.pdf \
	../output/developer_response_provisional_site_unit_multiples.pdf \
	../output/developer_response_provisional_site_construction_area_vs_units.pdf \
	../output/developer_response_provisional_site_construction_square_feet_per_unit.pdf \
	../output/developer_response_provisional_site_building_application_counts.pdf

../output/developer_response_provisional_site_panel.parquet: audit_developer_responses.R ../../../_lib/source_pipeline_utils.R ../input/dcp_housing_database_project_level_25q4.parquet ../input/dob_now_new_building_initial_filings.parquet | ../output
	$(R) $< $(HIST_PRE_START_YEAR) $(DESIGN_PRE_START_YEAR) $(PRE_END_YEAR) $(POST_YEAR) $(MIN_UNITS) $(DESIGN_MAX_UNITS) $(SITE_PLOT_MAX_UNITS) $(HIST_BIN_WIDTH)

../output/developer_response_application_panel.parquet ../output/developer_response_hdb_dob_join_qc.csv ../output/developer_response_site_definition_qc.csv ../output/developer_response_area_field_coverage.csv ../output/developer_response_design_summary.csv ../output/developer_response_exact_99_site_clusters.csv ../output/developer_response_provisional_site_unit_histogram.pdf ../output/developer_response_provisional_site_unit_multiples.pdf ../output/developer_response_provisional_site_construction_area_vs_units.pdf ../output/developer_response_provisional_site_construction_square_feet_per_unit.pdf ../output/developer_response_provisional_site_building_application_counts.pdf: ../output/developer_response_provisional_site_panel.parquet
	@test -s "$@"

../input/dcp_housing_database_project_level_25q4.parquet: ../../../stage_dcp_housing_database/output/dcp_housing_database_project_level_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dcp_housing_database_project_level_25q4.parquet ../input/dob_now_new_building_initial_filings.parquet

include ../../generic.make
