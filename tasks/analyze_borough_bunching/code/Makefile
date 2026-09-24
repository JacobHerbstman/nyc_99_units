include ../../shared/code/shell_functions.make

all: ../output/geographic_filings.parquet ../output/borough_summary.csv ../output/borough_bunching.pdf

include ../../shared/code/generic.make

../output/borough_bunching.pdf: borough_bunching.tex ../output/borough_filings.pdf ../output/borough_parents.pdf \
	../output/exact_99_map.pdf Makefile | ../output ../temp
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory=../temp $<
	cp ../temp/borough_bunching.pdf $@

../output/geographic_filings.parquet: construct_geographic_filings.R ../input/constituent_filing_panel.parquet \
	../input/dob_now_new_building_initial_filings.parquet \
	../input/dcp_housing_database_project_level_raw_23q4.parquet ../input/borough_boundaries_2026-09-08.geojson \
	Makefile | $(OOPR)
	$(R) $<

../output/borough_summary.csv: summarize_boroughs.R ../output/geographic_filings.parquet Makefile | $(OOPR)
	$(R) $<

../output/borough_%.pdf: plot_boroughs.R ../output/geographic_filings.parquet ../output/borough_summary.csv \
	Makefile | $(OOPR)
	$(R) $< $*

../output/exact_99_map.pdf: plot_exact_99_map.R ../output/geographic_filings.parquet \
	../input/borough_boundaries_2026-09-08.geojson Makefile | $(OOPR)
	$(R) $<

../input/constituent_filing_panel.parquet: ../../build_estimation_panels/output/constituent_filing_panel.parquet \
	| ../input
	ln -sf $< $@

../input/dob_now_new_building_initial_filings.parquet: \
	../../stage_dob_now_new_building_filings/output/dob_now_new_building_initial_filings.parquet | ../input
	ln -sf $< $@

../input/dcp_housing_database_project_level_raw_23q4.parquet: \
	../../stage_dcp_housing_database/output/dcp_housing_database_project_level_raw_23q4.parquet | ../input
	ln -sf $< $@

../input/borough_boundaries_2026-09-08.geojson: \
	../../fetch_nyc_borough_boundaries/output/borough_boundaries_2026-09-08.geojson | ../input
	ln -sf $< $@
