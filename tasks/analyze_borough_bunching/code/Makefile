include ../../shared/code/shell_functions.make

all: ../output/borough_bunching.pdf ../output/borough_summary.csv ../report/geographic_filings.txt \
	../report/borough_summary.txt

../output/borough_bunching.pdf: borough_bunching.tex ../output/borough_filings.pdf ../output/borough_parents.pdf \
	../output/exact_99_map.pdf Makefile | ../output
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=../output borough_bunching.tex

../output/geographic_filings.parquet: construct_geographic_filings.R ../input/constituent_filing_panel.parquet \
	../input/dob_now_new_building_initial_filings.parquet ../input/dcp_housing_database_project_level_raw_25q4.parquet \
	../input/borough_boundaries_2026-09-08.geojson Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/borough_summary.csv: summarize_boroughs.R ../output/geographic_filings.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/borough_%.pdf: plot_boroughs.R ../output/geographic_filings.parquet ../output/borough_summary.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $< $*

../output/exact_99_map.pdf: plot_exact_99_map.R ../output/geographic_filings.parquet \
	../input/borough_boundaries_2026-09-08.geojson Makefile ../../shared/code/shell_functions.make \
	../../shared/code/shell_functions.sh | ../output
	$(R) $<

../report/geographic_filings.txt: report_data.R ../output/geographic_filings.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< geographic_filings

../report/borough_summary.txt: report_data.R ../output/borough_summary.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< borough_summary

../input/constituent_filing_panel.parquet: ../../build_estimation_panels/output/constituent_filing_panel.parquet | \
	../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_housing_database_project_level_raw_25q4.parquet: \
	../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/borough_boundaries_2026-09-08.geojson: \
	../../fetch_nyc_borough_boundaries/output/borough_boundaries_2026-09-08.geojson | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

.PHONY: check-build_estimation_panels

check-build_estimation_panels:
	$(MAKE) -C ../../build_estimation_panels/code ../output/parent_opportunity_panel.parquet \
	../output/constituent_filing_panel.parquet ../report/parent_opportunity_panel.txt \
	../report/constituent_filing_panel.txt

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet

.PHONY: check-stage_dcp_housing_database

check-stage_dcp_housing_database:
	$(MAKE) -C ../../stage_dcp_housing_database/code all ../output/dcp_housing_database_project_level_raw_25q4.parquet

.PHONY: check-fetch_nyc_borough_boundaries

check-fetch_nyc_borough_boundaries:
	$(MAKE) -C ../../fetch_nyc_borough_boundaries/code all ../output/borough_boundaries_2026-09-08.geojson

../../build_estimation_panels/output/constituent_filing_panel.parquet: check-build_estimation_panels ;

../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet: check-stage_dob_now_new_building_filings ;

../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_25q4.parquet: check-stage_dcp_housing_database ;

../../fetch_nyc_borough_boundaries/output/borough_boundaries_2026-09-08.geojson: check-fetch_nyc_borough_boundaries ;

link-inputs: ../input/constituent_filing_panel.parquet ../input/dob_now_new_building_initial_filings.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet ../input/borough_boundaries_2026-09-08.geojson

include ../../shared/code/generic.make
