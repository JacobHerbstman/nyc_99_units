include ../../../shared/code/shell_functions.make

all: ../output/flatbush_floor_sensitivity.csv

include ../../../shared/code/generic.make

../output/flatbush_floor_sensitivity.csv: flatbush_floor_sensitivity.R flatbush_floor.make \
	../input/parent_opportunity_panel.parquet ../input/campus_covariate_crosswalk_rows.csv \
	../input/flatbush_geometry_overlap.csv ../../../shared/code/scale_shape_helpers.R \
	../../../shared/code/write_data_report.R | $(OOPR)
	$(R) $<

../input/parent_opportunity_panel.parquet: ../../../build_estimation_panels/output/parent_opportunity_panel.parquet | ../input
	ln -sf $< $@

../input/campus_covariate_crosswalk_rows.csv: ../../download_parent_review_documents/code/site_research_covariates_2026-09-21_campus/campus_covariate_crosswalk_rows.csv | ../input
	ln -sf $< $@

../input/flatbush_geometry_overlap.csv: ../../download_parent_review_documents/code/site_research_covariates_2026-09-21_campus/flatbush_geometry_overlap.csv | ../input
	ln -sf $< $@
