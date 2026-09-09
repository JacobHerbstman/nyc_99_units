include ../../shared/code/shell_functions.make

all: ../output/borough_bunching.pdf \
	../output/borough_summary.csv \
	../report/geographic_filings.txt \
	../report/borough_summary.txt

../output/borough_bunching.pdf: borough_bunching.tex ../output/borough_filings.pdf ../output/borough_parents.pdf ../output/exact_99_map.pdf Makefile | ../output
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=../output borough_bunching.tex

../output/geographic_filings.parquet: construct_geographic_filings.R ../input/constituent_filing_panel.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/dcp_housing_database_project_level_raw_25q4.parquet ../input/borough_boundaries_2026-09-08.geojson \
	Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/borough_summary.csv: summarize_boroughs.R ../output/geographic_filings.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<

../output/borough_%.pdf: plot_boroughs.R ../output/geographic_filings.parquet ../output/borough_summary.csv \
	Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $< $*

../output/exact_99_map.pdf: plot_exact_99_map.R ../output/geographic_filings.parquet \
	../input/borough_boundaries_2026-09-08.geojson Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../output
	$(R) $<

../report/geographic_filings.txt: report_data.R ../output/geographic_filings.parquet Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< geographic_filings

../report/borough_summary.txt: report_data.R ../output/borough_summary.csv Makefile \
	../../shared/code/shell_functions.make ../../shared/code/shell_functions.sh | ../report
	$(R) $< borough_summary

../input/constituent_filing_panel.parquet: ../../analyze_485x_scale_shape_splitting/output/constituent_filing_panel.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dob_now_new_building_initial_filings.parquet: ../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/dcp_housing_database_project_level_raw_25q4.parquet: ../../load_dcp_housing_database_raw/output/dcp_housing_database_project_level_raw_25q4.parquet | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../input/borough_boundaries_2026-09-08.geojson: ../../fetch_nyc_borough_boundaries/output/borough_boundaries_2026-09-08.geojson | ../input
	@test "$$(readlink "$@")" = "$<" || ln -sf "$<" "$@"

../../analyze_485x_scale_shape_splitting/output/constituent_filing_panel.parquet: check-analyze_485x_scale_shape_splitting ;

.PHONY: check-analyze_485x_scale_shape_splitting

check-analyze_485x_scale_shape_splitting:
	$(MAKE) -C ../../analyze_485x_scale_shape_splitting/code all ../output/constituent_filing_panel.parquet

../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet: check-stage_dob_now_new_building_filings ;

.PHONY: check-stage_dob_now_new_building_filings

check-stage_dob_now_new_building_filings:
	$(MAKE) -C ../../stage_dob_now_new_building_filings/code all ../output/dob_now_new_building_initial_filings.parquet

../../load_dcp_housing_database_raw/output/dcp_housing_database_project_level_raw_25q4.parquet: check-load_dcp_housing_database_raw ;

.PHONY: check-load_dcp_housing_database_raw

check-load_dcp_housing_database_raw:
	$(MAKE) -C ../../load_dcp_housing_database_raw/code all ../output/dcp_housing_database_project_level_raw_25q4.parquet

../../fetch_nyc_borough_boundaries/output/borough_boundaries_2026-09-08.geojson: check-fetch_nyc_borough_boundaries ;

.PHONY: check-fetch_nyc_borough_boundaries

check-fetch_nyc_borough_boundaries:
	$(MAKE) -C ../../fetch_nyc_borough_boundaries/code all ../output/borough_boundaries_2026-09-08.geojson

include ../../shared/code/generic.make
