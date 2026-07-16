SHELL := bash
include ../../shell_functions.make

DESIGN_PRE_START_YEAR := 2021
PRE_END_YEAR := 2023
POST_YEAR := 2025
MIN_UNITS := 50
DESIGN_MAX_UNITS := 150
SITE_PLOT_MAX_UNITS := 400

all: ../output/developer_response_provisional_site_construction_area_vs_units.pdf \
	../output/developer_response_provisional_site_construction_square_feet_per_unit.pdf \
	../output/developer_response_provisional_site_building_application_counts.pdf

../output/developer_response_provisional_site_construction_area_vs_units.pdf: summarize_developer_responses.R ../input/dob_now_new_building_initial_filings.parquet | ../output
	$(R) $< $(DESIGN_PRE_START_YEAR) $(PRE_END_YEAR) $(POST_YEAR) $(MIN_UNITS) $(DESIGN_MAX_UNITS) $(SITE_PLOT_MAX_UNITS)

../output/developer_response_provisional_site_construction_square_feet_per_unit.pdf \
../output/developer_response_provisional_site_building_application_counts.pdf: ../output/developer_response_provisional_site_construction_area_vs_units.pdf
	@test -s "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

link-inputs: ../input/dob_now_new_building_initial_filings.parquet

include ../../generic.make
